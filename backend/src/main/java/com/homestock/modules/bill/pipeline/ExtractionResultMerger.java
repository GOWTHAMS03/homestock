package com.homestock.modules.bill.pipeline;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

/**
 * Merges extraction results from printed and handwritten extraction pipelines
 * for MIXED documents (e.g., printed receipts with handwritten notes or additions).
 *
 * Resolves duplicates, consolidates line items, and maintains audit trails.
 */
@Service
public class ExtractionResultMerger {

    private static final Logger log = LoggerFactory.getLogger(ExtractionResultMerger.class);

    /**
     * Merges printed and handwritten results into a single cohesive extraction result.
     */
    public ReceiptExtractionResult merge(
            ReceiptExtractionResult printedResult,
            ReceiptExtractionResult handwrittenResult
    ) {
        if (printedResult == null && handwrittenResult == null) {
            return null;
        }
        if (printedResult == null || printedResult.getItems() == null || printedResult.getItems().isEmpty()) {
            return handwrittenResult;
        }
        if (handwrittenResult == null || handwrittenResult.getItems() == null || handwrittenResult.getItems().isEmpty()) {
            return printedResult;
        }

        log.info("Merging MIXED bill extraction: {} printed items, {} handwritten items",
                printedResult.getItems().size(), handwrittenResult.getItems().size());

        // Header info: Printed usually has much more reliable merchant/bill number/date info
        var merchantName = selectBestValue(printedResult.getMerchantName(), handwrittenResult.getMerchantName());
        var merchantAddress = selectBestValue(printedResult.getMerchantAddress(), handwrittenResult.getMerchantAddress());
        var billNumber = selectBestValue(printedResult.getBillNumber(), handwrittenResult.getBillNumber());
        var purchaseDate = selectBestValue(printedResult.getPurchaseDate(), handwrittenResult.getPurchaseDate());
        var purchaseTime = selectBestValue(printedResult.getPurchaseTime(), handwrittenResult.getPurchaseTime());
        var paymentMethod = selectBestValue(printedResult.getPaymentMethod(), handwrittenResult.getPaymentMethod());

        // Merge items with de-duplication
        List<ReceiptExtractionResult.ExtractedReceiptItem> mergedItems = new ArrayList<>();
        Set<Integer> matchedHandwrittenIndices = new HashSet<>();

        for (ReceiptExtractionResult.ExtractedReceiptItem printedItem : printedResult.getItems()) {
            ReceiptExtractionResult.ExtractedReceiptItem matchedHw = null;
            int bestHwIdx = -1;

            for (int i = 0; i < handwrittenResult.getItems().size(); i++) {
                if (matchedHandwrittenIndices.contains(i)) continue;
                ReceiptExtractionResult.ExtractedReceiptItem hwItem = handwrittenResult.getItems().get(i);

                if (isSameItem(printedItem, hwItem)) {
                    matchedHw = hwItem;
                    bestHwIdx = i;
                    break;
                }
            }

            if (matchedHw != null) {
                matchedHandwrittenIndices.add(bestHwIdx);
                // Merge identical item: prefer printed price/qty if valid, but enhance name if handwritten adds details
                ReceiptExtractionResult.ExtractedReceiptItem mergedItem = mergeItemPair(printedItem, matchedHw);
                mergedItems.add(mergedItem);
            } else {
                mergedItems.add(printedItem);
            }
        }

        // Add remaining handwritten items that were NOT part of printed text (e.g. handwritten additions)
        for (int i = 0; i < handwrittenResult.getItems().size(); i++) {
            if (!matchedHandwrittenIndices.contains(i)) {
                ReceiptExtractionResult.ExtractedReceiptItem extraHw = handwrittenResult.getItems().get(i);
                extraHw.setNeedsReview(true);
                if (extraHw.getReviewReason() == null) {
                    extraHw.setReviewReason("Handwritten addition to mixed bill");
                }
                mergedItems.add(extraHw);
            }
        }

        // Totals: Prefer printed totals if available, otherwise recalculate
        var grandTotal = selectBestDecimal(printedResult.getGrandTotal(), handwrittenResult.getGrandTotal());
        var subtotal = selectBestDecimal(printedResult.getSubtotal(), handwrittenResult.getSubtotal());
        var tax = selectBestDecimal(printedResult.getTax(), handwrittenResult.getTax());
        var discount = selectBestDecimal(printedResult.getDiscount(), handwrittenResult.getDiscount());

        // Overall confidence is weighted average
        double pConf = printedResult.getOverallConfidence() != null ? printedResult.getOverallConfidence().doubleValue() : 0.7;
        double hConf = handwrittenResult.getOverallConfidence() != null ? handwrittenResult.getOverallConfidence().doubleValue() : 0.7;
        BigDecimal overallConfidence = BigDecimal.valueOf((pConf * 0.6) + (hConf * 0.4)).setScale(2, RoundingMode.HALF_UP);

        return ReceiptExtractionResult.builder()
                .merchantName(merchantName)
                .merchantAddress(merchantAddress)
                .billNumber(billNumber)
                .purchaseDate(purchaseDate)
                .purchaseTime(purchaseTime)
                .paymentMethod(paymentMethod)
                .subtotal(subtotal)
                .tax(tax)
                .discount(discount)
                .grandTotal(grandTotal)
                .items(mergedItems)
                .overallConfidence(overallConfidence)
                .extractionNotes("Merged printed (" + printedResult.getAiProvider() + ") and handwritten results")
                .aiProvider("mixed-merger")
                .build();
    }

    private boolean isSameItem(
            ReceiptExtractionResult.ExtractedReceiptItem p,
            ReceiptExtractionResult.ExtractedReceiptItem h
    ) {
        if (p == null || h == null) return false;

        String pName = cleanForCompare(p.getNormalizedName() != null ? p.getNormalizedName() : p.getRawName());
        String hName = cleanForCompare(h.getNormalizedName() != null ? h.getNormalizedName() : h.getRawName());

        if (pName.isEmpty() || hName.isEmpty()) return false;

        // Exact or substring match
        if (pName.equals(hName) || pName.contains(hName) || hName.contains(pName)) {
            // If both have line totals, check that totals are close
            if (p.getLineTotal() != null && h.getLineTotal() != null
                    && p.getLineTotal().compareTo(BigDecimal.ZERO) > 0
                    && h.getLineTotal().compareTo(BigDecimal.ZERO) > 0) {
                BigDecimal diff = p.getLineTotal().subtract(h.getLineTotal()).abs();
                return diff.compareTo(BigDecimal.valueOf(5.0)) <= 0;
            }
            return true;
        }

        return false;
    }

    private ReceiptExtractionResult.ExtractedReceiptItem mergeItemPair(
            ReceiptExtractionResult.ExtractedReceiptItem p,
            ReceiptExtractionResult.ExtractedReceiptItem h
    ) {
        // Choose higher confidence field values
        String rawName = (p.getRawName() != null && !p.getRawName().isBlank()) ? p.getRawName() : h.getRawName();
        String normName = (p.getNormalizedName() != null && !p.getNormalizedName().isBlank()) ? p.getNormalizedName() : h.getNormalizedName();
        String brand = p.getBrand() != null ? p.getBrand() : h.getBrand();

        BigDecimal qty = (p.getQuantity() != null && p.getQuantity().compareTo(BigDecimal.ZERO) > 0) ? p.getQuantity() : h.getQuantity();
        String unit = (p.getUnit() != null && !p.getUnit().equals("pcs")) ? p.getUnit() : h.getUnit();
        BigDecimal unitPrice = (p.getUnitPrice() != null && p.getUnitPrice().compareTo(BigDecimal.ZERO) > 0) ? p.getUnitPrice() : h.getUnitPrice();
        BigDecimal lineTotal = (p.getLineTotal() != null && p.getLineTotal().compareTo(BigDecimal.ZERO) > 0) ? p.getLineTotal() : h.getLineTotal();

        return ReceiptExtractionResult.ExtractedReceiptItem.builder()
                .rawName(rawName)
                .normalizedName(normName)
                .brand(brand)
                .quantity(qty)
                .unit(unit)
                .unitPrice(unitPrice)
                .lineTotal(lineTotal)
                .discount(p.getDiscount())
                .tax(p.getTax())
                .nameConfidence(maxConf(p.getNameConfidence(), h.getNameConfidence()))
                .quantityConfidence(maxConf(p.getQuantityConfidence(), h.getQuantityConfidence()))
                .priceConfidence(maxConf(p.getPriceConfidence(), h.getPriceConfidence()))
                .overallConfidence(maxConf(p.getOverallConfidence(), h.getOverallConfidence()))
                .needsReview(p.isNeedsReview() || h.isNeedsReview())
                .reviewReason(p.getReviewReason() != null ? p.getReviewReason() : h.getReviewReason())
                .build();
    }

    private BigDecimal maxConf(BigDecimal a, BigDecimal b) {
        if (a == null) return b;
        if (b == null) return a;
        return a.compareTo(b) >= 0 ? a : b;
    }

    private String cleanForCompare(String s) {
        return s == null ? "" : s.toUpperCase().replaceAll("[^A-Z0-9]", "");
    }

    private <T> ReceiptExtractionResult.ConfidentValue<T> selectBestValue(
            ReceiptExtractionResult.ConfidentValue<T> a,
            ReceiptExtractionResult.ConfidentValue<T> b
    ) {
        if (a == null || a.getValue() == null) return b;
        if (b == null || b.getValue() == null) return a;
        if (a.getConfidence() == null) return b;
        if (b.getConfidence() == null) return a;
        return a.getConfidence().compareTo(b.getConfidence()) >= 0 ? a : b;
    }

    private ReceiptExtractionResult.ConfidentValue<BigDecimal> selectBestDecimal(
            ReceiptExtractionResult.ConfidentValue<BigDecimal> a,
            ReceiptExtractionResult.ConfidentValue<BigDecimal> b
    ) {
        if (a == null || a.getValue() == null) return b;
        if (b == null || b.getValue() == null) return a;
        if (a.getConfidence() == null) return b;
        if (b.getConfidence() == null) return a;
        return a.getConfidence().compareTo(b.getConfidence()) >= 0 ? a : b;
    }
}
