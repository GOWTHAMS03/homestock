package com.homestock.modules.product.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BarcodeInventoryRequest {

    @NotBlank(message = "Barcode is required")
    private String barcode;

    @NotNull(message = "Quantity is required")
    @Positive(message = "Quantity must be positive")
    private BigDecimal quantity;

    private String unit;
    private BigDecimal minimumQuantity;
    private LocalDate expiryDate;
    private String storageLocation;
    private BigDecimal purchasePrice;
    private String notes;
}
