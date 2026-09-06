package com.homestock.modules.purchase.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Data
public class CreatePurchaseRequest {
    private UUID storeId;

    private LocalDate purchaseDate = LocalDate.now();

    @NotNull(message = "Total amount is required")
    @DecimalMin(value = "0.0", message = "Total amount cannot be negative")
    private BigDecimal totalAmount;

    private String currency = "INR";
    private String notes;

    @NotEmpty(message = "Purchase must contain at least one item")
    @Valid
    private List<CreatePurchaseItemRequest> items;
}
