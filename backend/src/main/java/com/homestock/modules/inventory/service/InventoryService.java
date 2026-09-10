package com.homestock.modules.inventory.service;

import com.homestock.core.common.PagedResponse;
import com.homestock.core.exception.BusinessRuleException;
import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.core.storage.StorageService;
import com.homestock.core.util.SecurityUtils;
import com.homestock.modules.category.entity.Category;
import com.homestock.modules.category.repository.CategoryRepository;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.inventory.dto.*;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.entity.StockTransaction;
import com.homestock.modules.inventory.entity.TransactionType;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.inventory.repository.StockTransactionRepository;
import com.homestock.modules.shopping.service.ShoppingService;
import com.homestock.modules.notification.service.NotificationEngine;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class InventoryService {

    private final InventoryItemRepository inventoryItemRepository;
    private final StockTransactionRepository stockTransactionRepository;
    private final HomeRepository homeRepository;
    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;
    private final ShoppingService shoppingService;
    private final StorageService storageService;
    private final NotificationEngine notificationEngine;

    @Transactional(readOnly = true)
    public PagedResponse<InventoryItemDto> getItems(
            UUID homeId, UUID categoryId, String storageLocation, String query, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("name").ascending());

        Specification<InventoryItem> spec = (root, cq, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("home").get("id"), homeId));
            predicates.add(cb.isFalse(root.get("isArchived")));

            if (categoryId != null) {
                predicates.add(cb.equal(root.get("category").get("id"), categoryId));
            }
            if (storageLocation != null && !storageLocation.isBlank()) {
                predicates.add(cb.equal(cb.lower(root.get("storageLocation")), storageLocation.trim().toLowerCase()));
            }
            if (query != null && !query.isBlank()) {
                String pattern = "%" + query.trim().toLowerCase() + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(root.get("name")), pattern),
                        cb.like(cb.lower(root.get("brand")), pattern)
                ));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<InventoryItem> itemsPage = inventoryItemRepository.findAll(spec, pageable);
        Page<InventoryItemDto> dtoPage = itemsPage.map(InventoryItemDto::fromEntity);
        return PagedResponse.from(dtoPage);
    }

    @Transactional(readOnly = true)
    public InventoryItemDto getItemById(UUID homeId, UUID itemId) {
        InventoryItem item = inventoryItemRepository.findByIdAndHomeId(itemId, homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Inventory item not found"));
        return InventoryItemDto.fromEntity(item);
    }

    @Transactional
    public InventoryItemDto createItem(UUID homeId, CreateInventoryItemRequest request) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Home home = homeRepository.findById(homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Home not found"));

        Category category = null;
        if (request.getCategoryId() != null) {
            category = categoryRepository.findById(request.getCategoryId()).orElse(null);
        }

        InventoryItem item = InventoryItem.builder()
                .home(home)
                .category(category)
                .name(request.getName().trim())
                .brand(request.getBrand() != null ? request.getBrand().trim() : null)
                .quantity(request.getQuantity())
                .unit(request.getUnit().trim())
                .minimumQuantity(request.getMinimumQuantity())
                .maximumQuantity(request.getMaximumQuantity())
                .storageLocation(request.getStorageLocation())
                .purchasePrice(request.getPurchasePrice())
                .purchaseDate(request.getPurchaseDate())
                .expiryDate(request.getExpiryDate())
                .notes(request.getNotes())
                .imageUrl(request.getImageUrl())
                .isArchived(false)
                .build();

        InventoryItem savedItem = inventoryItemRepository.save(item);

        // Record initial stock transaction if quantity > 0
        if (savedItem.getQuantity().compareTo(BigDecimal.ZERO) > 0) {
            StockTransaction transaction = StockTransaction.builder()
                    .home(home)
                    .item(savedItem)
                    .user(currentUser)
                    .transactionType(TransactionType.STOCK_IN)
                    .quantityChange(savedItem.getQuantity())
                    .previousQuantity(BigDecimal.ZERO)
                    .newQuantity(savedItem.getQuantity())
                    .unit(savedItem.getUnit())
                    .reason("Initial stock addition")
                    .build();
            stockTransactionRepository.save(transaction);
        }

        // Check if item is created at or below low stock threshold
        if (savedItem.getQuantity().compareTo(savedItem.getMinimumQuantity()) <= 0) {
            shoppingService.handleAutoLowStock(home, savedItem, currentUser);
        }

        return InventoryItemDto.fromEntity(savedItem);
    }

    @Transactional
    public InventoryItemDto updateItem(UUID homeId, UUID itemId, UpdateInventoryItemRequest request) {
        InventoryItem item = inventoryItemRepository.findByIdAndHomeId(itemId, homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Inventory item not found"));

        if (request.getCategoryId() != null) {
            categoryRepository.findById(request.getCategoryId()).ifPresent(item::setCategory);
        } else {
            item.setCategory(null);
        }

        item.setName(request.getName().trim());
        item.setBrand(request.getBrand() != null ? request.getBrand().trim() : null);
        item.setUnit(request.getUnit().trim());
        item.setMinimumQuantity(request.getMinimumQuantity());
        item.setMaximumQuantity(request.getMaximumQuantity());
        item.setStorageLocation(request.getStorageLocation());
        item.setPurchasePrice(request.getPurchasePrice());
        item.setPurchaseDate(request.getPurchaseDate());
        item.setExpiryDate(request.getExpiryDate());
        item.setNotes(request.getNotes());

        InventoryItem updated = inventoryItemRepository.save(item);

        // Re-evaluate stock status after minimum threshold change
        if (updated.getQuantity().compareTo(updated.getMinimumQuantity()) <= 0) {
            UUID currentUserId = SecurityUtils.getCurrentUserId();
            User currentUser = userRepository.findById(currentUserId).orElse(null);
            shoppingService.handleAutoLowStock(item.getHome(), updated, currentUser);
        }

        return InventoryItemDto.fromEntity(updated);
    }

    @Transactional
    public InventoryItemDto updateStock(UUID homeId, UUID itemId, StockUpdateRequest request) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        InventoryItem item = inventoryItemRepository.findByIdAndHomeId(itemId, homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Inventory item not found"));

        BigDecimal currentQty = item.getQuantity();
        BigDecimal change = request.getQuantityChange();
        BigDecimal newQty;

        switch (request.getTransactionType()) {
            case STOCK_OUT, EXPIRED, DAMAGED -> {
                if (currentQty.compareTo(change) < 0) {
                    throw new BusinessRuleException("INSUFFICIENT_STOCK",
                            "Cannot reduce stock by " + change + " " + item.getUnit() + ". Only " + currentQty + " " + item.getUnit() + " available.");
                }
                newQty = currentQty.subtract(change);
            }
            case STOCK_IN -> newQty = currentQty.add(change);
            case ADJUSTMENT -> newQty = change;
            default -> throw new BusinessRuleException("Unsupported transaction type");
        }

        item.setQuantity(newQty);
        InventoryItem savedItem = inventoryItemRepository.save(item);

        // Record stock transaction history
        StockTransaction tx = StockTransaction.builder()
                .home(item.getHome())
                .item(savedItem)
                .user(currentUser)
                .transactionType(request.getTransactionType())
                .quantityChange(change)
                .previousQuantity(currentQty)
                .newQuantity(newQty)
                .unit(item.getUnit())
                .reason(request.getReason())
                .build();
        stockTransactionRepository.save(tx);
        notificationEngine.notifyStockUpdated(item.getHome(), currentUser, savedItem, change, item.getUnit());

        // Trigger automatic low stock evaluation
        if (newQty.compareTo(item.getMinimumQuantity()) <= 0) {
            shoppingService.handleAutoLowStock(item.getHome(), savedItem, currentUser);
        }

        return InventoryItemDto.fromEntity(savedItem);
    }

    @Transactional(readOnly = true)
    public PagedResponse<StockTransactionDto> getItemTransactions(UUID homeId, UUID itemId, int page, int size) {
        inventoryItemRepository.findByIdAndHomeId(itemId, homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Inventory item not found"));

        Pageable pageable = PageRequest.of(page, size);
        Page<StockTransaction> txPage = stockTransactionRepository.findAllByItemIdOrderByCreatedAtDesc(itemId, pageable);
        return PagedResponse.from(txPage.map(StockTransactionDto::fromEntity));
    }

    @Transactional
    public InventoryItemDto uploadItemImage(UUID homeId, UUID itemId, MultipartFile file) {
        InventoryItem item = inventoryItemRepository.findByIdAndHomeId(itemId, homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Inventory item not found"));

        if (item.getImageUrl() != null) {
            storageService.deleteFile(item.getImageUrl());
        }

        String fileUrl = storageService.storeFile(file, "items");
        item.setImageUrl(fileUrl);
        return InventoryItemDto.fromEntity(inventoryItemRepository.save(item));
    }

    @Transactional
    public void deleteItem(UUID homeId, UUID itemId) {
        InventoryItem item = inventoryItemRepository.findByIdAndHomeId(itemId, homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Inventory item not found"));
        item.setIsArchived(true);
        inventoryItemRepository.save(item);
    }
}
