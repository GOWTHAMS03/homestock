package com.homestock.modules.smartshopping.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Request payload when a user reports or records a local/offline store price.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LocalPriceReportRequest {

    private UUID productId;

    @NotBlank(message = "Item name is required")
    private String itemName;

    @NotBlank(message = "Store name is required")
    private String storeName;

    @NotNull(message = "Price is required")
    @DecimalMin(value = "0.01", message = "Price must be positive")
    private BigDecimal price;

    private BigDecimal quantity;

    private String unit;
}
