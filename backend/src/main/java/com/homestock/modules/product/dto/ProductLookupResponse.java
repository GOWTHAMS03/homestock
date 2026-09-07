package com.homestock.modules.product.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductLookupResponse {
    private boolean found;
    private String barcode;
    private String barcodeType;
    private ProductDto product;
    private ExistingInventorySummary existingInventoryItem;
    private ExistingShoppingSummary existingShoppingListItem;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExistingInventorySummary {
        private UUID id;
        private String name;
        private BigDecimal currentQuantity;
        private BigDecimal minimumQuantity;
        private String unit;
        private String storageLocation;
        private String expiryDate;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExistingShoppingSummary {
        private UUID id;
        private String name;
        private BigDecimal quantity;
        private String unit;
        private boolean isCompleted;
    }
}
