package com.homestock.modules.shop.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopProductRequest {

    private UUID productId; // Link to global product catalog (optional)

    @NotBlank(message = "Product name is required")
    @Size(max = 255)
    private String productName;

    @Size(max = 100)
    private String brand;

    private BigDecimal packageSize;

    @Size(max = 30)
    private String unit;

    @NotNull(message = "Price is required")
    @DecimalMin(value = "0.01", message = "Price must be positive")
    private BigDecimal price;

    @DecimalMin(value = "0.01")
    private BigDecimal mrp;

    @DecimalMin(value = "0.01")
    private BigDecimal offerPrice;

    private Instant offerStart;
    private Instant offerEnd;

    @Size(max = 20)
    private String availabilityStatus; // AVAILABLE, LIMITED, OUT_OF_STOCK

    @DecimalMin(value = "0")
    private BigDecimal stockQuantity;

    @Size(max = 20)
    private String stockVisibility; // STATUS_ONLY, QUANTITY

    @Size(max = 50)
    private String barcode;
}
