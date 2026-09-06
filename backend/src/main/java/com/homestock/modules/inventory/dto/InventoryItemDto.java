package com.homestock.modules.inventory.dto;

import com.homestock.modules.inventory.entity.ExpiryStatus;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.entity.StockStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InventoryItemDto {
    private UUID id;
    private UUID homeId;
    private UUID categoryId;
    private String categoryName;
    private String categoryIcon;
    private String categoryColor;
    private String name;
    private String brand;
    private BigDecimal quantity;
    private String unit;
    private BigDecimal minimumQuantity;
    private BigDecimal maximumQuantity;
    private String storageLocation;
    private BigDecimal purchasePrice;
    private LocalDate purchaseDate;
    private LocalDate expiryDate;
    private String imageUrl;
    private String notes;
    private StockStatus stockStatus;
    private ExpiryStatus expiryStatus;
    private Long daysUntilExpiry;
    private Instant createdAt;
    private Instant updatedAt;

    public static InventoryItemDto fromEntity(InventoryItem item) {
        if (item == null) return null;
        return InventoryItemDto.builder()
                .id(item.getId())
                .homeId(item.getHome().getId())
                .categoryId(item.getCategory() != null ? item.getCategory().getId() : null)
                .categoryName(item.getCategory() != null ? item.getCategory().getName() : "Uncategorized")
                .categoryIcon(item.getCategory() != null ? item.getCategory().getIcon() : "category")
                .categoryColor(item.getCategory() != null ? item.getCategory().getColorHex() : "#6366F1")
                .name(item.getName())
                .brand(item.getBrand())
                .quantity(item.getQuantity())
                .unit(item.getUnit())
                .minimumQuantity(item.getMinimumQuantity())
                .maximumQuantity(item.getMaximumQuantity())
                .storageLocation(item.getStorageLocation())
                .purchasePrice(item.getPurchasePrice())
                .purchaseDate(item.getPurchaseDate())
                .expiryDate(item.getExpiryDate())
                .imageUrl(item.getImageUrl())
                .notes(item.getNotes())
                .stockStatus(item.calculateStockStatus())
                .expiryStatus(item.calculateExpiryStatus())
                .daysUntilExpiry(item.getDaysUntilExpiry())
                .createdAt(item.getCreatedAt())
                .updatedAt(item.getUpdatedAt())
                .build();
    }
}
