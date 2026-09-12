package com.homestock.modules.deals.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PriceDetails {
    private BigDecimal price;
    private BigDecimal mrp;
    @Builder.Default
    private BigDecimal deliveryCharge = BigDecimal.ZERO;
    @Builder.Default
    private BigDecimal discount = BigDecimal.ZERO;
    @Builder.Default
    private BigDecimal couponDiscount = BigDecimal.ZERO;
    @Builder.Default
    private String currency = "INR";
    private boolean verified;
}
