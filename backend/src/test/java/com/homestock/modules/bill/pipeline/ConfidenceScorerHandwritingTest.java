package com.homestock.modules.bill.pipeline;

import com.homestock.modules.bill.entity.DocumentType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class ConfidenceScorerHandwritingTest {

    private ConfidenceScorer scorer;

    @BeforeEach
    void setUp() {
        scorer = new ConfidenceScorer();
        ReflectionTestUtils.setField(scorer, "autoAcceptThreshold", 0.90);
        ReflectionTestUtils.setField(scorer, "needsReviewThreshold", 0.70);
        ReflectionTestUtils.setField(scorer, "rejectThreshold", 0.30);
    }

    @Test
    void testHandwrittenDocumentRequiresConfirmationEvenWithHighConfidence() {
        var aiResult = ReceiptExtractionResult.builder()
                .overallConfidence(new BigDecimal("0.95"))
                .items(List.of(
                        ReceiptExtractionResult.ExtractedReceiptItem.builder()
                                .rawName("Rice 1kg")
                                .normalizedName("Rice")
                                .quantity(new BigDecimal("1.0"))
                                .lineTotal(new BigDecimal("60.00"))
                                .needsReview(false)
                                .build()
                ))
                .build();

        var validation = BillMathValidator.BillValidationResult.builder()
                .status("VALID")
                .isReconciled(true)
                .build();

        var result = scorer.calculateBillConfidence(
                new BigDecimal("0.90"),
                0.0, // OCR 0 because handwriting was parsed by multimodal vision
                aiResult,
                validation,
                List.of(new BigDecimal("95.0")),
                DocumentType.HANDWRITTEN
        );

        assertNotNull(result);
        assertTrue(result.getOverallConfidence().doubleValue() >= 0.80);
        // Handwritten documents should NOT be AUTO_ACCEPT; they must require user confirmation
        assertEquals("NEEDS_CONFIRMATION", result.getRecommendedAction());
    }

    @Test
    void testPrintedDocumentAllowsAutoAcceptWhenConfidenceIsHigh() {
        var aiResult = ReceiptExtractionResult.builder()
                .overallConfidence(new BigDecimal("0.95"))
                .items(List.of(
                        ReceiptExtractionResult.ExtractedReceiptItem.builder()
                                .rawName("Rice 1kg")
                                .normalizedName("Rice")
                                .quantity(new BigDecimal("1.0"))
                                .lineTotal(new BigDecimal("60.00"))
                                .needsReview(false)
                                .build()
                ))
                .build();

        var validation = BillMathValidator.BillValidationResult.builder()
                .status("VALID")
                .isReconciled(true)
                .build();

        var result = scorer.calculateBillConfidence(
                new BigDecimal("0.95"),
                0.95,
                aiResult,
                validation,
                List.of(new BigDecimal("95.0")),
                DocumentType.PRINTED
        );

        assertNotNull(result);
        assertTrue(result.getOverallConfidence().doubleValue() >= 0.90);
        assertEquals("AUTO_ACCEPT", result.getRecommendedAction());
    }
}
