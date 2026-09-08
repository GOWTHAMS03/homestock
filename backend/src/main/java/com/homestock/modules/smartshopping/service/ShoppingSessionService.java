package com.homestock.modules.smartshopping.service;

import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.purchase.dto.CreatePurchaseItemRequest;
import com.homestock.modules.purchase.dto.CreatePurchaseRequest;
import com.homestock.modules.purchase.dto.PurchaseDto;
import com.homestock.modules.purchase.service.PurchaseService;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.smartshopping.dto.CompleteSessionRequest;
import com.homestock.modules.smartshopping.dto.LocalPriceReportRequest;
import com.homestock.modules.smartshopping.entity.PriceHistory;
import com.homestock.modules.smartshopping.entity.ShoppingSession;
import com.homestock.modules.smartshopping.entity.ShoppingSessionItem;
import com.homestock.modules.smartshopping.repository.PriceHistoryRepository;
import com.homestock.modules.smartshopping.repository.ShoppingSessionItemRepository;
import com.homestock.modules.smartshopping.repository.ShoppingSessionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.*;

/**
 * Service managing the shopping session lifecycle and purchase completion.
 * Restocks inventory, marks shopping list items completed, updates price trends,
 * and feeds data to the consumption learning engine.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ShoppingSessionService {

    private final ShoppingSessionRepository sessionRepository;
    private final ShoppingSessionItemRepository sessionItemRepository;
    private final ShoppingListItemRepository shoppingListItemRepository;
    private final InventoryItemRepository inventoryItemRepository;
    private final PurchaseService purchaseService;
    private final PriceHistoryRepository priceHistoryRepository;

    /**
     * Create a new shopping session tracking user's comparison state.
     */
    @Transactional
    public ShoppingSession createSession(
            UUID homeId,
            UUID userId,
            List<UUID> itemIds,
            String selectedProviders,
            BigDecimal estimatedTotal,
            String recommendedOption
    ) {
        ShoppingSession session = ShoppingSession.builder()
                .homeId(homeId)
                .userId(userId)
                .startedAt(Instant.now())
                .status("CREATED")
                .selectedProviders(selectedProviders)
                .estimatedTotal(estimatedTotal)
                .recommendedOption(recommendedOption)
                .build();

        ShoppingSession savedSession = sessionRepository.save(session);

        if (itemIds != null) {
            for (UUID itemId : itemIds) {
                ShoppingListItem item = shoppingListItemRepository.findById(itemId).orElse(null);
                if (item != null) {
                    ShoppingSessionItem sessionItem = ShoppingSessionItem.builder()
                            .sessionId(savedSession.getId())
                            .shoppingListItemId(itemId)
                            .itemName(item.getItemName())
                            .quantity(item.getQuantity())
                            .unit(item.getUnit())
                            .productId(item.getProduct() != null ? item.getProduct().getId() : null)
                            .build();
                    sessionItemRepository.save(sessionItem);
                }
            }
        }

        return savedSession;
    }

    /**
     * Completes a shopping session: records the purchase, updates inventory,
     * completes shopping items, triggers consumption recalculation, and updates session.
     */
    @Transactional
    public PurchaseDto completeSession(UUID homeId, UUID userId, UUID sessionId, CompleteSessionRequest request) {
        ShoppingSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Shopping session not found: " + sessionId));

        // 1. Build CreatePurchaseRequest
        CreatePurchaseRequest purchaseRequest = new CreatePurchaseRequest();
        purchaseRequest.setPurchaseDate(LocalDate.now());
        purchaseRequest.setTotalAmount(request.getTotalAmount());
        purchaseRequest.setCurrency("INR");
        purchaseRequest.setNotes(request.getNotes() != null ? request.getNotes() : "Completed via Smart Shopping (" + request.getStoreName() + ")");

        List<InventoryItem> homeInventory = inventoryItemRepository.findAllByHomeIdAndIsArchivedFalseOrderByNameAsc(homeId);
        List<CreatePurchaseItemRequest> purchaseItems = new ArrayList<>();

        for (CompleteSessionRequest.SessionPurchaseItemDto itemDto : request.getItems()) {
            CreatePurchaseItemRequest pItem = new CreatePurchaseItemRequest();
            pItem.setItemName(itemDto.getItemName());
            pItem.setQuantity(itemDto.getQuantity() != null ? itemDto.getQuantity() : BigDecimal.ONE);
            pItem.setUnit(itemDto.getUnit() != null ? itemDto.getUnit() : "pcs");
            pItem.setUnitPrice(itemDto.getUnitPrice() != null ? itemDto.getUnitPrice() : BigDecimal.ZERO);
            pItem.setTotalPrice(itemDto.getTotalPrice() != null ? itemDto.getTotalPrice() :
                    pItem.getQuantity().multiply(pItem.getUnitPrice()));

            // Resolve Inventory Item to restock
            UUID targetInventoryId = itemDto.getInventoryItemId();
            if (targetInventoryId == null && itemDto.getShoppingListItemId() != null) {
                ShoppingListItem sli = shoppingListItemRepository.findById(itemDto.getShoppingListItemId()).orElse(null);
                if (sli != null && sli.getInventoryItem() != null) {
                    targetInventoryId = sli.getInventoryItem().getId();
                }
            }

            // Fallback: match by name
            if (targetInventoryId == null) {
                String search = itemDto.getItemName().trim().toLowerCase();
                for (InventoryItem inv : homeInventory) {
                    if (inv.getName().trim().equalsIgnoreCase(search)) {
                        targetInventoryId = inv.getId();
                        break;
                    }
                }
            }
            pItem.setInventoryItemId(targetInventoryId);
            purchaseItems.add(pItem);

            // Record into price history for local/provider tracking
            recordPriceSnapshot(userId, itemDto, request.getStoreName());
        }

        purchaseRequest.setItems(purchaseItems);

        // 2. Delegate to purchase service (handles transactional inventory restock,
        // stock transactions, shopping list item completion, and consumption learning)
        PurchaseDto purchaseResult = purchaseService.recordPurchase(homeId, purchaseRequest);

        // 3. Mark session items as purchased
        List<ShoppingSessionItem> sessionItems = sessionItemRepository.findBySessionId(sessionId);
        for (ShoppingSessionItem ssi : sessionItems) {
            for (CompleteSessionRequest.SessionPurchaseItemDto pid : request.getItems()) {
                if ((ssi.getShoppingListItemId() != null && ssi.getShoppingListItemId().equals(pid.getShoppingListItemId()))
                        || ssi.getItemName().equalsIgnoreCase(pid.getItemName())) {
                    ssi.setPurchased(true);
                    ssi.setActualPrice(pid.getTotalPrice());
                    ssi.setSelectedProvider(request.getStoreName());
                    sessionItemRepository.save(ssi);
                    break;
                }
            }
        }

        // 4. Finalize session
        session.setStatus("COMPLETED");
        session.setCompletedAt(Instant.now());
        session.setActualTotal(request.getTotalAmount());
        if (session.getEstimatedTotal() != null && request.getTotalAmount() != null) {
            BigDecimal savings = session.getEstimatedTotal().subtract(request.getTotalAmount());
            session.setPotentialSavings(savings.compareTo(BigDecimal.ZERO) > 0 ? savings : BigDecimal.ZERO);
        }
        sessionRepository.save(session);

        log.info("[ShoppingSession] Completed session {} for home {}. Purchase recorded with {} items.",
                sessionId, homeId, purchaseItems.size());

        return purchaseResult;
    }

    /**
     * Records a user-reported price from a local / physical store.
     */
    @Transactional
    public PriceHistory recordLocalPrice(UUID homeId, UUID userId, LocalPriceReportRequest request) {
        BigDecimal unitPrice = request.getPrice();
        if (request.getQuantity() != null && request.getQuantity().compareTo(BigDecimal.ZERO) > 0) {
            unitPrice = request.getPrice().divide(request.getQuantity(), 4, java.math.RoundingMode.HALF_UP);
        }

        PriceHistory priceRecord = PriceHistory.builder()
                .provider("Local Store")
                .providerProductId("local_" + UUID.randomUUID())
                .productName(request.getItemName())
                .price(request.getPrice())
                .unitPrice(unitPrice)
                .deliveryCharge(BigDecimal.ZERO)
                .effectivePrice(request.getPrice())
                .currency("INR")
                .recordedAt(Instant.now())
                .productId(request.getProductId())
                .isUserReported(true)
                .reportedBy(userId)
                .storeName(request.getStoreName())
                .availability("IN_STOCK")
                .build();

        return priceHistoryRepository.save(priceRecord);
    }

    private void recordPriceSnapshot(UUID userId, CompleteSessionRequest.SessionPurchaseItemDto itemDto, String storeName) {
        try {
            PriceHistory ph = PriceHistory.builder()
                    .provider(itemDto.getProvider() != null ? itemDto.getProvider() : (storeName != null ? storeName : "Unknown"))
                    .providerProductId(itemDto.getProviderProductId() != null ? itemDto.getProviderProductId() : "pur_" + UUID.randomUUID())
                    .productName(itemDto.getItemName())
                    .price(itemDto.getTotalPrice() != null ? itemDto.getTotalPrice() : BigDecimal.ZERO)
                    .unitPrice(itemDto.getUnitPrice())
                    .deliveryCharge(BigDecimal.ZERO)
                    .effectivePrice(itemDto.getTotalPrice() != null ? itemDto.getTotalPrice() : BigDecimal.ZERO)
                    .currency("INR")
                    .recordedAt(Instant.now())
                    .productId(itemDto.getProductId())
                    .isUserReported(true)
                    .reportedBy(userId)
                    .storeName(storeName)
                    .availability("IN_STOCK")
                    .build();
            priceHistoryRepository.save(ph);
        } catch (Exception e) {
            log.warn("[ShoppingSession] Could not record price snapshot: {}", e.getMessage());
        }
    }
}
