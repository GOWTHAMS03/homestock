package com.homestock.modules.smartshopping.engine.url;

import com.homestock.modules.smartshopping.dto.ProductUrlType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Result of validating a product URL against retailer URL rules and ProductIdentity.
 * Conforms to Sections 43, 44, 45, 51.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductUrlValidationResult {
    private ProductUrlType urlType;
    private boolean urlVerified;
    private double urlConfidence; // 0.0 to 1.0
    private String canonicalProductUrl;
    private String validationMessage;
    private ProductUrlMetadata metadata;
    private boolean directProductUrlAvailable;

    public static ProductUrlValidationResult invalid(String message) {
        return ProductUrlValidationResult.builder()
                .urlType(ProductUrlType.INVALID_URL)
                .urlVerified(false)
                .urlConfidence(0.0)
                .validationMessage(message)
                .directProductUrlAvailable(false)
                .build();
    }

    public static ProductUrlValidationResult rejected(ProductUrlType type, String message) {
        return ProductUrlValidationResult.builder()
                .urlType(type)
                .urlVerified(false)
                .urlConfidence(0.0)
                .validationMessage(message)
                .directProductUrlAvailable(false)
                .build();
    }
}
