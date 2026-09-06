package com.homestock.modules.inventory.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Data
public class CreateInventoryItemRequest {
    @NotBlank(message = "Item name is required")
    @Size(min = 1, max = 150)
    private String name;

    private UUID categoryId;

    private String brand;

    @NotNull(message = "Quantity is required")
    @DecimalMin(value = "0.0", message = "Quantity cannot be negative")
    private BigDecimal quantity = BigDecimal.ZERO;

    @NotBlank(message = "Unit is required")
    private String unit = "pcs";

    @NotNull(message = "Minimum quantity is required")
    @DecimalMin(value = "0.0", message = "Minimum quantity cannot be negative")
    private BigDecimal minimumQuantity = BigDecimal.ONE;

    private BigDecimal maximumQuantity;

    private String storageLocation;

    private BigDecimal purchasePrice;

    private LocalDate purchaseDate;

    private LocalDate expiryDate;

    private String notes;

    private String imageUrl;
}
