package com.homestock.modules.purchase.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.util.UUID;

@Data
public class CreatePurchaseItemRequest {
    private UUID inventoryItemId; // optional link to inventory item to restock

    @NotBlank(message = "Item name is required")
    private String itemName;

    private UUID categoryId;

    @NotNull(message = "Quantity is required")
    @DecimalMin(value = "0.001", message = "Quantity must be greater than zero")
    private BigDecimal quantity;

    private String unit = "pcs";

    @DecimalMin(value = "0.0", message = "Unit price cannot be negative")
    private BigDecimal unitPrice = BigDecimal.ZERO;

    @DecimalMin(value = "0.0", message = "Total price cannot be negative")
    private BigDecimal totalPrice = BigDecimal.ZERO;
}
