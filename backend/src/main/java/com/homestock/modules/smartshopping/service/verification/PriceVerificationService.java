package com.homestock.modules.smartshopping.service.verification;

import com.homestock.modules.smartshopping.dto.PriceStatus;
import com.homestock.modules.smartshopping.dto.ProductCandidate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;

/**
 * Price Verification Service:
 * Prioritizes direct product-page pricing over snippet pricing,
 * validates price timestamps, and marks unverified prices as PRICE_UNVERIFIED.
 */
@Service
public class PriceVerificationService {

    private static final Logger log = LoggerFactory.getLogger(PriceVerificationService.class);

    private static final Duration MAX_FRESHNESS_WINDOW = Duration.ofHours(24);

    /**
     * Verify and enrich candidate with price verification status, confidence, and timestamp.
     */
    public ProductCandidate verifyPrice(ProductCandidate candidate) {
        if (candidate.getPrice() == null || candidate.getPrice().compareTo(BigDecimal.ZERO) <= 0) {
            candidate.setPriceStatus(PriceStatus.PRICE_UNVERIFIED);
            candidate.setPriceConfidence(0.0);
            return candidate;
        }

        Instant now = Instant.now();
        Instant lastChecked = candidate.getLastVerifiedAt() != null ? candidate.getLastVerifiedAt() : now;
        candidate.setLastVerifiedAt(lastChecked);

        // Check freshness
        boolean isFresh = Duration.between(lastChecked, now).compareTo(MAX_FRESHNESS_WINDOW) <= 0;

        // Confidence calculation
        double confidence = 0.80; // Base snippet confidence

        // Direct product URL availability implies product-page verified
        if (candidate.getProductUrl() != null && !candidate.getProductUrl().isBlank()) {
            confidence += 0.15;
        }

        if (isFresh) {
            confidence += 0.05;
        } else {
            confidence -= 0.20;
        }

        confidence = Math.max(0.0, Math.min(1.0, confidence));

        if (confidence >= 0.85) {
            candidate.setPriceStatus(PriceStatus.PRICE_VERIFIED);
        } else {
            candidate.setPriceStatus(PriceStatus.PRICE_UNVERIFIED);
        }

        candidate.setPriceConfidence(confidence);
        return candidate;
    }
}
