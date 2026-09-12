package com.homestock.modules.deals.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Result of the Final Payable Price calculation.
 * Final Price = Product Price + Delivery Charge + Applicable Fees - Discounts - Coupons.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FinalPriceResult {
    private BigDecimal productPrice;
    private BigDecimal deliveryCharge;
    private BigDecimal discount;
    private BigDecimal couponDiscount;
    private BigDecimal finalPrice;
    private double priceConfidence; // 0.0 to 1.0
    private boolean deliveryChargesMayApply;
    private String explanation;
}
