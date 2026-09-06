package com.homestock.modules.dashboard.service;

import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.dashboard.dto.DashboardSummaryDto;
import com.homestock.modules.dashboard.dto.NeedsAttentionItemDto;
import com.homestock.modules.dashboard.dto.RecommendationItemDto;
import com.homestock.modules.dashboard.dto.WhatDoINeedResponse;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.inventory.entity.ExpiryStatus;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.entity.StockStatus;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.shopping.entity.ShoppingList;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.shopping.repository.ShoppingListRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final HomeRepository homeRepository;
    private final InventoryItemRepository inventoryItemRepository;
    private final ShoppingListRepository shoppingListRepository;
    private final ShoppingListItemRepository shoppingListItemRepository;

    @Transactional(readOnly = true)
    public DashboardSummaryDto getDashboardSummary(UUID homeId) {
        Home home = homeRepository.findById(homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Home not found"));

        long totalItems = inventoryItemRepository.countByHomeIdAndIsArchivedFalse(homeId);
        long lowStock = inventoryItemRepository.countLowStock(homeId);
        long outOfStock = inventoryItemRepository.countOutOfStock(homeId);

        long pendingShopping = 0;
        Optional<ShoppingList> defaultList = shoppingListRepository.findByHomeIdAndIsDefaultTrue(homeId);
        if (defaultList.isPresent()) {
            pendingShopping = shoppingListItemRepository.countByShoppingListIdAndIsCompletedFalse(defaultList.get().getId());
        }

        LocalDate today = LocalDate.now();
        LocalDate in7Days = today.plusDays(7);
        List<InventoryItem> expiringSoonItems = inventoryItemRepository.findExpiringSoonItems(homeId, today, in7Days);
        List<InventoryItem> expiredItems = inventoryItemRepository.findExpiredItems(homeId, today);

        List<NeedsAttentionItemDto> attentionList = new ArrayList<>();

        // 1. Out of stock items
        List<InventoryItem> outOfStockItems = inventoryItemRepository.findOutOfStockItems(homeId);
        for (InventoryItem item : outOfStockItems) {
            attentionList.add(NeedsAttentionItemDto.builder()
                    .itemId(item.getId())
                    .name(item.getName())
                    .categoryName(item.getCategory() != null ? item.getCategory().getName() : "General")
                    .quantity(item.getQuantity())
                    .unit(item.getUnit())
                    .stockStatus(StockStatus.OUT_OF_STOCK)
                    .expiryStatus(item.calculateExpiryStatus())
                    .expiryDate(item.getExpiryDate())
                    .daysUntilExpiry(item.getDaysUntilExpiry())
                    .reasonMessage(item.getName() + " is out of stock")
                    .build());
        }

        // 2. Low stock items (not out of stock)
        List<InventoryItem> lowStockItems = inventoryItemRepository.findLowStockItems(homeId);
        for (InventoryItem item : lowStockItems) {
            if (item.getQuantity().compareTo(BigDecimal.ZERO) > 0) {
                attentionList.add(NeedsAttentionItemDto.builder()
                        .itemId(item.getId())
                        .name(item.getName())
                        .categoryName(item.getCategory() != null ? item.getCategory().getName() : "General")
                        .quantity(item.getQuantity())
                        .unit(item.getUnit())
                        .stockStatus(StockStatus.LOW_STOCK)
                        .expiryStatus(item.calculateExpiryStatus())
                        .expiryDate(item.getExpiryDate())
                        .daysUntilExpiry(item.getDaysUntilExpiry())
                        .reasonMessage(item.getName() + " is running low (" + item.getQuantity() + " " + item.getUnit() + " remaining)")
                        .build());
            }
        }

        // 3. Expiring soon items
        for (InventoryItem item : expiringSoonItems) {
            long days = item.getDaysUntilExpiry() != null ? item.getDaysUntilExpiry() : 0;
            String expiryMsg = days == 0 ? item.getName() + " expires today" :
                    (days == 1 ? item.getName() + " expires tomorrow" : item.getName() + " expires in " + days + " days");

            attentionList.add(NeedsAttentionItemDto.builder()
                    .itemId(item.getId())
                    .name(item.getName())
                    .categoryName(item.getCategory() != null ? item.getCategory().getName() : "General")
                    .quantity(item.getQuantity())
                    .unit(item.getUnit())
                    .stockStatus(item.calculateStockStatus())
                    .expiryStatus(ExpiryStatus.EXPIRING_SOON)
                    .expiryDate(item.getExpiryDate())
                    .daysUntilExpiry(days)
                    .reasonMessage(expiryMsg)
                    .build());
        }

        return DashboardSummaryDto.builder()
                .homeName(home.getName())
                .totalInventoryItems(totalItems)
                .lowStockCount(lowStock)
                .outOfStockCount(outOfStock)
                .pendingShoppingCount(pendingShopping)
                .expiringSoonCount(expiringSoonItems.size() + expiredItems.size())
                .needsAttention(attentionList)
                .build();
    }

    @Transactional(readOnly = true)
    public WhatDoINeedResponse getWhatDoINeed(UUID homeId) {
        homeRepository.findById(homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Home not found"));

        List<InventoryItem> lowStockItems = inventoryItemRepository.findLowStockItems(homeId);
        LocalDate today = LocalDate.now();
        List<InventoryItem> expiringSoon = inventoryItemRepository.findExpiringSoonItems(homeId, today, today.plusDays(5));

        List<RecommendationItemDto> urgent = new ArrayList<>();
        List<RecommendationItemDto> soon = new ArrayList<>();
        List<RecommendationItemDto> optional = new ArrayList<>();
        Set<UUID> processedIds = new HashSet<>();

        // URGENT: Out of stock or critically below minimum (< 50% of min)
        for (InventoryItem item : lowStockItems) {
            BigDecimal halfMin = item.getMinimumQuantity().multiply(BigDecimal.valueOf(0.5));
            if (item.getQuantity().compareTo(BigDecimal.ZERO) == 0) {
                BigDecimal restock = item.getMaximumQuantity() != null ?
                        item.getMaximumQuantity() : item.getMinimumQuantity().multiply(BigDecimal.valueOf(2));
                urgent.add(RecommendationItemDto.builder()
                        .itemId(item.getId())
                        .name(item.getName())
                        .categoryName(item.getCategory() != null ? item.getCategory().getName() : "General")
                        .currentQuantity(item.getQuantity())
                        .recommendedQuantity(restock.compareTo(BigDecimal.ZERO) == 0 ? BigDecimal.ONE : restock)
                        .unit(item.getUnit())
                        .rationale("Out of stock")
                        .build());
                processedIds.add(item.getId());
            } else if (item.getQuantity().compareTo(halfMin) <= 0) {
                BigDecimal restock = item.getMaximumQuantity() != null ?
                        item.getMaximumQuantity().subtract(item.getQuantity()) : item.getMinimumQuantity();
                urgent.add(RecommendationItemDto.builder()
                        .itemId(item.getId())
                        .name(item.getName())
                        .categoryName(item.getCategory() != null ? item.getCategory().getName() : "General")
                        .currentQuantity(item.getQuantity())
                        .recommendedQuantity(restock.compareTo(BigDecimal.ZERO) == 0 ? BigDecimal.ONE : restock)
                        .unit(item.getUnit())
                        .rationale("Critically low (less than half of minimum)")
                        .build());
                processedIds.add(item.getId());
            }
        }

        // SOON: Normal low stock or expiring soon
        for (InventoryItem item : lowStockItems) {
            if (!processedIds.contains(item.getId())) {
                BigDecimal restock = item.getMaximumQuantity() != null ?
                        item.getMaximumQuantity().subtract(item.getQuantity()) : item.getMinimumQuantity();
                soon.add(RecommendationItemDto.builder()
                        .itemId(item.getId())
                        .name(item.getName())
                        .categoryName(item.getCategory() != null ? item.getCategory().getName() : "General")
                        .currentQuantity(item.getQuantity())
                        .recommendedQuantity(restock.compareTo(BigDecimal.ZERO) == 0 ? BigDecimal.ONE : restock)
                        .unit(item.getUnit())
                        .rationale("Below minimum threshold")
                        .build());
                processedIds.add(item.getId());
            }
        }

        for (InventoryItem item : expiringSoon) {
            if (!processedIds.contains(item.getId())) {
                soon.add(RecommendationItemDto.builder()
                        .itemId(item.getId())
                        .name(item.getName())
                        .categoryName(item.getCategory() != null ? item.getCategory().getName() : "General")
                        .currentQuantity(item.getQuantity())
                        .recommendedQuantity(item.getMinimumQuantity())
                        .unit(item.getUnit())
                        .rationale("Expiring in " + item.getDaysUntilExpiry() + " days - replace soon")
                        .build());
                processedIds.add(item.getId());
            }
        }

        return WhatDoINeedResponse.builder()
                .urgent(urgent)
                .soon(soon)
                .optional(optional)
                .build();
    }
}
