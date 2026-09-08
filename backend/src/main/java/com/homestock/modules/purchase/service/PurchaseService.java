package com.homestock.modules.purchase.service;

import com.homestock.core.common.PagedResponse;
import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.core.util.SecurityUtils;
import com.homestock.modules.category.entity.Category;
import com.homestock.modules.category.repository.CategoryRepository;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.entity.StockTransaction;
import com.homestock.modules.inventory.entity.TransactionType;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.inventory.repository.StockTransactionRepository;
import com.homestock.modules.purchase.dto.CreatePurchaseItemRequest;
import com.homestock.modules.purchase.dto.CreatePurchaseRequest;
import com.homestock.modules.purchase.dto.PurchaseDto;
import com.homestock.modules.purchase.entity.Purchase;
import com.homestock.modules.purchase.entity.PurchaseItem;
import com.homestock.modules.purchase.repository.PurchaseItemRepository;
import com.homestock.modules.purchase.repository.PurchaseRepository;
import com.homestock.modules.shopping.entity.ShoppingList;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.shopping.repository.ShoppingListRepository;
import com.homestock.modules.store.entity.Store;
import com.homestock.modules.store.repository.StoreRepository;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PurchaseService {

    private static final Logger log = LoggerFactory.getLogger(PurchaseService.class);

    private final PurchaseRepository purchaseRepository;
    private final PurchaseItemRepository purchaseItemRepository;
    private final HomeRepository homeRepository;
    private final StoreRepository storeRepository;
    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final InventoryItemRepository inventoryItemRepository;
    private final StockTransactionRepository stockTransactionRepository;
    private final ShoppingListRepository shoppingListRepository;
    private final ShoppingListItemRepository shoppingListItemRepository;
    private final com.homestock.modules.consumption.service.ConsumptionService consumptionService;

    @Transactional
    public PurchaseDto recordPurchase(UUID homeId, CreatePurchaseRequest request) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Home home = homeRepository.findById(homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Home not found"));

        Store store = null;
        if (request.getStoreId() != null) {
            store = storeRepository.findByIdAndHomeId(request.getStoreId(), homeId).orElse(null);
        }

        Purchase purchase = Purchase.builder()
                .home(home)
                .store(store)
                .recordedBy(currentUser)
                .purchaseDate(request.getPurchaseDate() != null ? request.getPurchaseDate() : LocalDate.now())
                .totalAmount(request.getTotalAmount())
                .currency(request.getCurrency() != null ? request.getCurrency() : "INR")
                .notes(request.getNotes())
                .build();

        Purchase savedPurchase = purchaseRepository.save(purchase);
        List<PurchaseItem> purchaseItems = new ArrayList<>();

        Optional<ShoppingList> defaultShoppingListOpt = shoppingListRepository.findByHomeIdAndIsDefaultTrue(homeId);

        for (CreatePurchaseItemRequest itemReq : request.getItems()) {
            InventoryItem inventoryItem = null;
            if (itemReq.getInventoryItemId() != null) {
                inventoryItem = inventoryItemRepository.findByIdAndHomeId(itemReq.getInventoryItemId(), homeId).orElse(null);
            }

            Category category = null;
            if (itemReq.getCategoryId() != null) {
                category = categoryRepository.findById(itemReq.getCategoryId()).orElse(null);
            } else if (inventoryItem != null && inventoryItem.getCategory() != null) {
                category = inventoryItem.getCategory();
            }

            PurchaseItem pItem = PurchaseItem.builder()
                    .purchase(savedPurchase)
                    .inventoryItem(inventoryItem)
                    .itemName(itemReq.getItemName().trim())
                    .category(category)
                    .quantity(itemReq.getQuantity())
                    .unit(itemReq.getUnit() != null ? itemReq.getUnit().trim() : "pcs")
                    .unitPrice(itemReq.getUnitPrice())
                    .totalPrice(itemReq.getTotalPrice() != null && itemReq.getTotalPrice().compareTo(BigDecimal.ZERO) > 0 ?
                            itemReq.getTotalPrice() : itemReq.getQuantity().multiply(itemReq.getUnitPrice()))
                    .build();

            purchaseItems.add(purchaseItemRepository.save(pItem));

            // 1. If linked to an inventory item, automatically increase inventory stock & log STOCK_IN
            if (inventoryItem != null) {
                BigDecimal previousQty = inventoryItem.getQuantity();
                BigDecimal newQty = previousQty.add(itemReq.getQuantity());
                inventoryItem.setQuantity(newQty);
                if (itemReq.getUnitPrice() != null && itemReq.getUnitPrice().compareTo(BigDecimal.ZERO) > 0) {
                    inventoryItem.setPurchasePrice(itemReq.getUnitPrice());
                }
                inventoryItem.setPurchaseDate(purchase.getPurchaseDate());
                inventoryItemRepository.save(inventoryItem);

                String storeName = store != null ? store.getName() : "Purchase";
                StockTransaction tx = StockTransaction.builder()
                        .home(home)
                        .item(inventoryItem)
                        .user(currentUser)
                        .transactionType(TransactionType.STOCK_IN)
                        .quantityChange(itemReq.getQuantity())
                        .previousQuantity(previousQty)
                        .newQuantity(newQty)
                        .unit(itemReq.getUnit())
                        .reason("Restocked via purchase at " + storeName)
                        .build();
                stockTransactionRepository.save(tx);

                // 2. Mark related shopping list item as completed if it was on the list
                if (defaultShoppingListOpt.isPresent()) {
                    shoppingListItemRepository.findActiveItemByInventoryItemId(defaultShoppingListOpt.get().getId(), inventoryItem.getId())
                            .ifPresent(shoppingItem -> {
                                shoppingItem.setIsCompleted(true);
                                shoppingItem.setCompletedBy(currentUser);
                                shoppingItem.setCompletedAt(Instant.now());
                                shoppingListItemRepository.save(shoppingItem);
                                log.info("Auto-completed shopping item '{}' after purchase", shoppingItem.getItemName());
                            });
                }

                // 3. Trigger Consumption Learning Engine
                consumptionService.onPurchaseRecorded(home, inventoryItem, itemReq.getQuantity(), purchase.getPurchaseDate());
            }
        }

        savedPurchase.getItems().clear();
        savedPurchase.getItems().addAll(purchaseItems);
        log.info("Purchase of {} items recorded successfully for home '{}' by user '{}'",
                purchaseItems.size(), home.getName(), currentUser.getFullName());

        return PurchaseDto.fromEntity(savedPurchase);
    }

    @Transactional(readOnly = true)
    public PagedResponse<PurchaseDto> getPurchases(UUID homeId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Purchase> purchasesPage = purchaseRepository.findAllByHomeIdOrderByPurchaseDateDescCreatedAtDesc(homeId, pageable);
        return PagedResponse.from(purchasesPage.map(PurchaseDto::fromEntity));
    }

    @Transactional(readOnly = true)
    public PurchaseDto getPurchaseById(UUID homeId, UUID purchaseId) {
        Purchase purchase = purchaseRepository.findByIdAndHomeId(purchaseId, homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Purchase record not found"));
        return PurchaseDto.fromEntity(purchase);
    }
}
