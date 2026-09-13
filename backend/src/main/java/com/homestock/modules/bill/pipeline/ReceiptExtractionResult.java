package com.homestock.modules.bill.pipeline;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * Structured result from AI receipt extraction.
 * Every field includes a confidence score and needsReview flag.
 * NEVER contains hallucinated values — uncertain fields are null with needsReview=true.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReceiptExtractionResult {

    // Merchant metadata
    private ConfidentValue<String> merchantName;
    private ConfidentValue<String> merchantAddress;
    private ConfidentValue<String> billNumber;
    private ConfidentValue<String> purchaseDate;
    private ConfidentValue<String> purchaseTime;
    private ConfidentValue<String> paymentMethod;

    // Financial totals
    private ConfidentValue<BigDecimal> subtotal;
    private ConfidentValue<BigDecimal> discount;
    private ConfidentValue<BigDecimal> tax;
    private ConfidentValue<BigDecimal> grandTotal;

    // Extracted items
    @Builder.Default
    private List<ExtractedReceiptItem> items = new ArrayList<>();

    // Overall extraction confidence
    private BigDecimal overallConfidence;
    private String extractionNotes;

    private String aiProvider;
    private String aiModel;

    /**
     * A value with associated confidence score and review flag.
     * If the AI cannot confidently determine a value, it should be null with needsReview=true.
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ConfidentValue<T> {
        private T value;
        @Builder.Default
        private BigDecimal confidence = BigDecimal.ZERO;
        @Builder.Default
        private boolean needsReview = true;

        public static <T> ConfidentValue<T> confident(T value, double confidence) {
            return ConfidentValue.<T>builder()
                    .value(value)
                    .confidence(BigDecimal.valueOf(confidence))
                    .needsReview(confidence < 0.80)
                    .build();
        }

        public static <T> ConfidentValue<T> uncertain(T value, double confidence) {
            return ConfidentValue.<T>builder()
                    .value(value)
                    .confidence(BigDecimal.valueOf(confidence))
                    .needsReview(true)
                    .build();
        }

        public static <T> ConfidentValue<T> unknown() {
            return ConfidentValue.<T>builder()
                    .value(null)
                    .confidence(BigDecimal.ZERO)
                    .needsReview(true)
                    .build();
        }
    }

    /**
     * A single item extracted from the receipt.
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExtractedReceiptItem {
        private String rawName;          // as it appears on the receipt
        private String normalizedName;   // cleaned/normalized form
        private String brand;
        private BigDecimal quantity;
        private String unit;
        private BigDecimal unitPrice;
        private BigDecimal lineTotal;
        private BigDecimal discount;
        private BigDecimal tax;

        // Per-field confidence
        @Builder.Default
        private BigDecimal nameConfidence = BigDecimal.ZERO;
        @Builder.Default
        private BigDecimal quantityConfidence = BigDecimal.ZERO;
        @Builder.Default
        private BigDecimal priceConfidence = BigDecimal.ZERO;
        @Builder.Default
        private BigDecimal overallConfidence = BigDecimal.ZERO;

        @Builder.Default
        private boolean needsReview = false;
        private String reviewReason;
    }
}
