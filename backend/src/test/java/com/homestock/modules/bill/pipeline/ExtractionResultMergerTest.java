package com.homestock.modules.bill.pipeline;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class ExtractionResultMergerTest {

    private ExtractionResultMerger merger;

    @BeforeEach
    void setUp() {
        merger = new ExtractionResultMerger();
    }

    @Test
    void testMergePrintedAndHandwrittenNonOverlapping() {
        var printedItem = ReceiptExtractionResult.ExtractedReceiptItem.builder()
                .rawName("AASHIRVAAD ATTA 5KG")
                .normalizedName("Aashirvaad Whole Wheat Atta")
                .quantity(new BigDecimal("1.0"))
                .unit("kg")
                .unitPrice(new BigDecimal("245.00"))
                .lineTotal(new BigDecimal("245.00"))
                .nameConfidence(new BigDecimal("0.95"))
                .priceConfidence(new BigDecimal("0.95"))
                .quantityConfidence(new BigDecimal("0.95"))
                .build();

        var printedResult = ReceiptExtractionResult.builder()
                .merchantName(ReceiptExtractionResult.ConfidentValue.confident("Supermarket", 0.90))
                .grandTotal(ReceiptExtractionResult.ConfidentValue.confident(new BigDecimal("245.00"), 0.95))
                .items(new ArrayList<>(List.of(printedItem)))
                .overallConfidence(new BigDecimal("0.92"))
                .aiProvider("gemini-printed")
                .build();

        var handwrittenItem = ReceiptExtractionResult.ExtractedReceiptItem.builder()
                .rawName("துவரம்பருப்பு 1kg")
                .normalizedName("Toor Dal")
                .quantity(new BigDecimal("1.0"))
                .unit("kg")
                .unitPrice(new BigDecimal("160.00"))
                .lineTotal(new BigDecimal("160.00"))
                .nameConfidence(new BigDecimal("0.85"))
                .priceConfidence(new BigDecimal("0.80"))
                .quantityConfidence(new BigDecimal("0.85"))
                .build();

        var handwrittenResult = ReceiptExtractionResult.builder()
                .grandTotal(ReceiptExtractionResult.ConfidentValue.confident(new BigDecimal("160.00"), 0.80))
                .items(new ArrayList<>(List.of(handwrittenItem)))
                .overallConfidence(new BigDecimal("0.80"))
                .aiProvider("gemini-handwriting")
                .build();

        var merged = merger.merge(printedResult, handwrittenResult);

        assertNotNull(merged);
        assertEquals(2, merged.getItems().size());
        assertEquals("Supermarket", merged.getMerchantName().getValue());
        // Handwritten item added with review flag
        assertTrue(merged.getItems().stream().anyMatch(i -> "Toor Dal".equals(i.getNormalizedName()) && i.isNeedsReview()));
    }

    @Test
    void testMergeDeduplicationOfIdenticalItems() {
        var printedItem = ReceiptExtractionResult.ExtractedReceiptItem.builder()
                .rawName("MILK 1L")
                .normalizedName("Milk")
                .quantity(new BigDecimal("1.0"))
                .unit("l")
                .unitPrice(new BigDecimal("30.00"))
                .lineTotal(new BigDecimal("30.00"))
                .nameConfidence(new BigDecimal("0.90"))
                .priceConfidence(new BigDecimal("0.95"))
                .quantityConfidence(new BigDecimal("0.95"))
                .build();

        var printedResult = ReceiptExtractionResult.builder()
                .items(new ArrayList<>(List.of(printedItem)))
                .grandTotal(ReceiptExtractionResult.ConfidentValue.confident(new BigDecimal("30.00"), 0.90))
                .build();

        var handwrittenItem = ReceiptExtractionResult.ExtractedReceiptItem.builder()
                .rawName("Milk 1L")
                .normalizedName("Milk")
                .quantity(new BigDecimal("1.0"))
                .unit("l")
                .unitPrice(new BigDecimal("30.00"))
                .lineTotal(new BigDecimal("30.00"))
                .nameConfidence(new BigDecimal("0.70"))
                .priceConfidence(new BigDecimal("0.70"))
                .quantityConfidence(new BigDecimal("0.70"))
                .build();

        var handwrittenResult = ReceiptExtractionResult.builder()
                .items(new ArrayList<>(List.of(handwrittenItem)))
                .grandTotal(ReceiptExtractionResult.ConfidentValue.confident(new BigDecimal("30.00"), 0.70))
                .build();

        var merged = merger.merge(printedResult, handwrittenResult);

        assertNotNull(merged);
        // Deduplicated into 1 item
        assertEquals(1, merged.getItems().size());
        assertEquals(new BigDecimal("30.00"), merged.getItems().get(0).getLineTotal());
    }
}
