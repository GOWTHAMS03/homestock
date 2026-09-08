package com.homestock.modules.smartshopping.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotEmpty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Request payload when user completes a shopping session.
 * Records the purchase, updates inventory, marks shopping list items completed,
 * and triggers consumption learning.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CompleteSessionRequest {

    private String storeName;

    @DecimalMin(value = "0.0", message = "Total amount cannot be negative")
    private BigDecimal totalAmount;

    private String notes;

    @NotEmpty(message = "Session must contain at least one purchased item")
    private List<SessionPurchaseItemDto> items;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SessionPurchaseItemDto {
        private UUID shoppingListItemId;
        private UUID inventoryItemId;
        private UUID productId;
        private String itemName;
        private BigDecimal quantity;
        private String unit;
        private BigDecimal unitPrice;
        private BigDecimal totalPrice;
        private String provider;
        private String providerProductId;
    }
}
