package com.homestock.modules.deals.service;

import com.homestock.modules.deals.model.DealCandidateInput;
import com.homestock.modules.deals.model.FinalPriceResult;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

/**
 * Calculates Final Payable Price with transparent delivery charges, discounts, and fees.
 * Phase 9 — Final Payable Price.
 */
@Service
public class FinalPriceCalculationService {

    public FinalPriceResult calculateFinalPrice(DealCandidateInput candidate) {
        if (candidate == null || candidate.getPrice() == null) {
            return FinalPriceResult.builder()
                    .productPrice(BigDecimal.ZERO)
                    .deliveryCharge(BigDecimal.ZERO)
                    .discount(BigDecimal.ZERO)
                    .couponDiscount(BigDecimal.ZERO)
                    .finalPrice(BigDecimal.ZERO)
                    .priceConfidence(0.0)
                    .deliveryChargesMayApply(true)
                    .explanation("Price information missing")
                    .build();
        }

        BigDecimal productPrice = candidate.getPrice();
        BigDecimal deliveryCharge = candidate.getDeliveryCharge() != null ? candidate.getDeliveryCharge() : BigDecimal.ZERO;
        BigDecimal discount = candidate.getDiscount() != null ? candidate.getDiscount() : BigDecimal.ZERO;
        BigDecimal couponDiscount = candidate.getCouponDiscount() != null ? candidate.getCouponDiscount() : BigDecimal.ZERO;

        boolean deliveryKnown = candidate.getDeliveryCharge() != null;
        double confidence = deliveryKnown ? 1.0 : 0.85;

        // Compute total payable
        BigDecimal finalPrice = productPrice
                .add(deliveryCharge)
                .subtract(discount)
                .subtract(couponDiscount);

        if (finalPrice.compareTo(BigDecimal.ZERO) < 0) {
            finalPrice = productPrice;
        }

        String explanation;
        if (deliveryKnown && deliveryCharge.compareTo(BigDecimal.ZERO) == 0) {
            explanation = "Free delivery included";
        } else if (deliveryKnown && deliveryCharge.compareTo(BigDecimal.ZERO) > 0) {
            explanation = String.format("Includes ₹%.2f delivery charge", deliveryCharge.doubleValue());
        } else {
            explanation = "Delivery charges may apply at checkout";
        }

        return FinalPriceResult.builder()
                .productPrice(productPrice)
                .deliveryCharge(deliveryCharge)
                .discount(discount)
                .couponDiscount(couponDiscount)
                .finalPrice(finalPrice)
                .priceConfidence(confidence)
                .deliveryChargesMayApply(!deliveryKnown)
                .explanation(explanation)
                .build();
    }
}
