package com.homestock.modules.bill.pipeline;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

/**
 * Multi-level confidence scoring for bill extraction results.
 *
 * Confidence levels:
 *   imageConfidence     = quality analysis score
 *   ocrConfidence       = OCR provider's reported confidence
 *   fieldConfidence     = per-field from AI extraction
 *   itemConfidence      = weighted min of field confidences
 *   matchConfidence     = inventory matching score
 *   billConfidence      = overall bill confidence
 *
 * Critical financial fields (price, quantity) have HIGHER weight.
 * A single low-confidence price field reduces the final score significantly.
 */
@Service
public class ConfidenceScorer {

    private static final Logger log = LoggerFactory.getLogger(ConfidenceScorer.class);

    @Value("${app.bill.confidence.auto-accept:0.90}")
    private double autoAcceptThreshold;

    @Value("${app.bill.confidence.needs-review:0.70}")
    private double needsReviewThreshold;

    @Value("${app.bill.confidence.reject:0.30}")
    private double rejectThreshold;

    /**
     * Calculate overall bill confidence from all pipeline stages (default PRINTED).
     */
    public BillConfidenceResult calculateBillConfidence(
            BigDecimal imageQuality,
            double ocrConfidence,
            ReceiptExtractionResult aiResult,
            BillMathValidator.BillValidationResult validation,
            List<BigDecimal> matchConfidences
    ) {
        return calculateBillConfidence(imageQuality, ocrConfidence, aiResult, validation, matchConfidences, com.homestock.modules.bill.entity.DocumentType.PRINTED);
    }

    /**
     * Calculate overall bill confidence from all pipeline stages with DocumentType awareness.
     */
    public BillConfidenceResult calculateBillConfidence(
            BigDecimal imageQuality,
            double ocrConfidence,
            ReceiptExtractionResult aiResult,
            BillMathValidator.BillValidationResult validation,
            List<BigDecimal> matchConfidences,
            com.homestock.modules.bill.entity.DocumentType documentType
    ) {
        double imgConf = imageQuality != null ? imageQuality.doubleValue() : 0.7;
        double ocrConf = Math.max(0, Math.min(1, ocrConfidence));

        // AI extraction confidence
        double aiConf = aiResult != null && aiResult.getOverallConfidence() != null
                ? aiResult.getOverallConfidence().doubleValue()
                : 0.5;

        // Validation confidence
        double validConf = 0.5;
        if (validation != null) {
            if ("VALID".equals(validation.getStatus())) validConf = 1.0;
            else if ("MINOR_DISCREPANCY".equals(validation.getStatus())) validConf = 0.75;
            else if ("NEEDS_REVIEW".equals(validation.getStatus())) validConf = 0.40;
            else validConf = 0.20;
        }

        // Average match confidence
        double matchConf = 0.5;
        if (matchConfidences != null && !matchConfidences.isEmpty()) {
            matchConf = matchConfidences.stream()
                    .mapToDouble(BigDecimal::doubleValue)
                    .average()
                    .orElse(0.5);
            // Normalize from 0-100 scale to 0-1 if needed
            if (matchConf > 1.0) matchConf = matchConf / 100.0;
        }

        // Weighted composite — for handwritten documents, multimodal vision carries primary weight
        double composite;
        if (documentType == com.homestock.modules.bill.entity.DocumentType.HANDWRITTEN) {
            composite = (imgConf * 0.10)
                    + (aiConf * 0.45)
                    + (validConf * 0.25)
                    + (matchConf * 0.20);
        } else {
            composite = (imgConf * 0.10)
                    + (ocrConf * 0.15)
                    + (aiConf * 0.30)
                    + (validConf * 0.25)
                    + (matchConf * 0.20);
        }

        // Apply penalty for validation failures
        if (validation != null && !validation.isReconciled()) {
            composite = Math.min(composite, 0.65);
        }

        // Items with needsReview reduce overall confidence
        int needsReviewCount = 0;
        int totalItems = 0;
        if (aiResult != null && aiResult.getItems() != null) {
            totalItems = aiResult.getItems().size();
            needsReviewCount = (int) aiResult.getItems().stream()
                    .filter(ReceiptExtractionResult.ExtractedReceiptItem::isNeedsReview)
                    .count();
        }
        if (totalItems > 0 && needsReviewCount > 0) {
            double reviewPenalty = (double) needsReviewCount / totalItems * 0.20;
            composite -= reviewPenalty;
        }

        composite = Math.max(0.0, Math.min(1.0, composite));

        // Determine action — handwritten bills always require user confirmation
        String action;
        if (composite >= autoAcceptThreshold && documentType != com.homestock.modules.bill.entity.DocumentType.HANDWRITTEN) {
            action = "AUTO_ACCEPT";
        } else if (composite >= needsReviewThreshold) {
            action = "NEEDS_CONFIRMATION";
        } else if (composite >= rejectThreshold) {
            action = "NEEDS_REVIEW";
        } else {
            action = "MANUAL_ENTRY";
        }

        log.info("Bill confidence: {} [img={}, ocr={}, ai={}, valid={}, match={}] → {}",
                String.format("%.2f", composite),
                String.format("%.2f", imgConf),
                String.format("%.2f", ocrConf),
                String.format("%.2f", aiConf),
                String.format("%.2f", validConf),
                String.format("%.2f", matchConf),
                action);

        return BillConfidenceResult.builder()
                .overallConfidence(BigDecimal.valueOf(composite).setScale(2, RoundingMode.HALF_UP))
                .imageConfidence(BigDecimal.valueOf(imgConf).setScale(2, RoundingMode.HALF_UP))
                .ocrConfidence(BigDecimal.valueOf(ocrConf).setScale(2, RoundingMode.HALF_UP))
                .aiConfidence(BigDecimal.valueOf(aiConf).setScale(2, RoundingMode.HALF_UP))
                .validationConfidence(BigDecimal.valueOf(validConf).setScale(2, RoundingMode.HALF_UP))
                .matchConfidence(BigDecimal.valueOf(matchConf).setScale(2, RoundingMode.HALF_UP))
                .recommendedAction(action)
                .needsReviewCount(needsReviewCount)
                .totalItems(totalItems)
                .build();
    }

    /**
     * Calculate individual item confidence from field-level confidences.
     * Critical financial fields have higher weight and can drag down the composite.
     */
    public BigDecimal calculateItemConfidence(
            BigDecimal nameConfidence,
            BigDecimal quantityConfidence,
            BigDecimal priceConfidence,
            BigDecimal matchConfidence
    ) {
        double name = safeDouble(nameConfidence);
        double qty = safeDouble(quantityConfidence);
        double price = safeDouble(priceConfidence);
        double match = safeDouble(matchConfidence);
        // Normalize match from 0-100 to 0-1 if needed
        if (match > 1.0) match = match / 100.0;

        // Weighted — price is most critical
        double weighted = (name * 0.20) + (qty * 0.20) + (price * 0.40) + (match * 0.20);

        // Penalty if any critical field is very low
        double minCritical = Math.min(price, Math.min(name, qty));
        if (minCritical < 0.30) {
            weighted = Math.min(weighted, 0.45);
        }

        return BigDecimal.valueOf(Math.max(0.0, Math.min(1.0, weighted)))
                .setScale(2, RoundingMode.HALF_UP);
    }

    public boolean shouldAutoAccept(BigDecimal confidence) {
        return confidence != null && confidence.doubleValue() >= autoAcceptThreshold;
    }

    public boolean needsReview(BigDecimal confidence) {
        return confidence == null || confidence.doubleValue() < autoAcceptThreshold;
    }

    private double safeDouble(BigDecimal value) {
        return value != null ? value.doubleValue() : 0.0;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class BillConfidenceResult {
        private BigDecimal overallConfidence;
        private BigDecimal imageConfidence;
        private BigDecimal ocrConfidence;
        private BigDecimal aiConfidence;
        private BigDecimal validationConfidence;
        private BigDecimal matchConfidence;
        private String recommendedAction; // AUTO_ACCEPT, NEEDS_CONFIRMATION, NEEDS_REVIEW, MANUAL_ENTRY
        private int needsReviewCount;
        private int totalItems;
    }
}
