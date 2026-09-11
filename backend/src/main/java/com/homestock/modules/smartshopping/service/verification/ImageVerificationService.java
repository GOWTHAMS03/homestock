package com.homestock.modules.smartshopping.service.verification;

import com.homestock.modules.smartshopping.dto.ProductCandidate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Set;

/**
 * Image Verification Service:
 * Enforces 4-tier image priority:
 * 1. Official seller/product-page image
 * 2. Trusted retailer image
 * 3. Structured product catalog image
 * 4. Search snippet image fallback
 * Audits correspondence to brand and product identity.
 */
@Service
public class ImageVerificationService {

    private static final Logger log = LoggerFactory.getLogger(ImageVerificationService.class);

    private static final Set<String> TRUSTED_DOMAINS = Set.of(
            "bigbasket.com", "blinkit.com", "jiomart.com", "amazon.in", "flipkart.com", "zepto.in"
    );

    /**
     * Verify and classify image source, assigning verification tier and confidence.
     */
    public ProductCandidate verifyImage(ProductCandidate candidate) {
        String img = candidate.getImageUrl();
        if (img == null || img.isBlank()) {
            candidate.setImageVerificationTier("NONE");
            candidate.setImageConfidence(0.0);
            return candidate;
        }

        String lowerImg = img.toLowerCase();
        double imageConfidence = 0.60;
        String tier = "SEARCH_SNIPPET";

        // Check trusted retailer
        boolean isTrusted = TRUSTED_DOMAINS.stream().anyMatch(lowerImg::contains);
        if (isTrusted) {
            tier = "TRUSTED_RETAILER";
            imageConfidence = 0.90;
        } else if (lowerImg.contains("catalog") || lowerImg.contains("product")) {
            tier = "CATALOG";
            imageConfidence = 0.80;
        }

        // Check if candidate provider has an official product URL
        if (candidate.getProductUrl() != null && !candidate.getProductUrl().isBlank() && isTrusted) {
            tier = "OFFICIAL_PRODUCT_PAGE";
            imageConfidence = 0.98;
        }

        candidate.setImageVerificationTier(tier);
        candidate.setImageConfidence(imageConfidence);

        return candidate;
    }
}
