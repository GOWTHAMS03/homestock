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
public class ShopDealRequest {

    private UUID shopProductId;

    @NotBlank(message = "Deal title is required")
    @Size(max = 200)
    private String title;

    @Size(max = 1000)
    private String description;

    @Size(max = 30)
    private String dealType; // DISCOUNT, SPECIAL_PRICE, BUY_X_GET_Y, LIMITED_TIME

    @DecimalMin(value = "0.01")
    private BigDecimal originalPrice;

    @DecimalMin(value = "0.01")
    private BigDecimal offerPrice;

    @DecimalMin(value = "0.01")
    @DecimalMax(value = "100.0")
    private BigDecimal discountPercent;

    @NotNull(message = "Start date is required")
    private Instant startDate;

    @NotNull(message = "End date is required")
    private Instant endDate;
}
