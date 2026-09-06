package com.homestock.modules.shopping.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.util.UUID;

@Data
public class CreateShoppingItemRequest {
    private UUID inventoryItemId; // optional link to inventory

    @NotBlank(message = "Item name is required")
    private String itemName;

    private UUID categoryId;

    @NotNull(message = "Quantity is required")
    @DecimalMin(value = "0.001", message = "Quantity must be greater than zero")
    private BigDecimal quantity = BigDecimal.ONE;

    private String unit = "pcs";
    private String notes;
}
