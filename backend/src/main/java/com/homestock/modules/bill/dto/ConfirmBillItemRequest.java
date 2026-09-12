package com.homestock.modules.bill.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
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
public class ConfirmBillItemRequest {
    @NotBlank(message = "Item name is required")
    private String rawItemName;

    private String productName;
    private String brand;
    private String categoryName;

    private UUID inventoryItemId;
    private UUID productId;
    private UUID shoppingListItemId;

    @NotNull(message = "Quantity is required")
    @Positive(message = "Quantity must be positive")
    private BigDecimal quantity;

    @NotBlank(message = "Unit is required")
    private String unit;

    @NotNull(message = "Unit price is required")
    private BigDecimal unitPrice;

    private BigDecimal mrp;
    private BigDecimal discount;
    private BigDecimal tax;

    @NotNull(message = "Final price is required")
    private BigDecimal finalPrice;

    private String barcode;
}
