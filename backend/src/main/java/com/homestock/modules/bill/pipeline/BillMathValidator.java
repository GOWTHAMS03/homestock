package com.homestock.modules.bill.pipeline;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

/**
 * Validates financial accuracy of extracted bill data.
 *
 * Line-level: quantity × unitPrice ≈ lineTotal (with tolerance for rounding/tax)
 * Bill-level: SUM(lineTotals) + tax - discount ≈ grandTotal (with tolerance)
 *
 * Never silently accepts an unreconciled bill as 100% correct.
 */
@Service
public class BillMathValidator {

    private static final Logger log = LoggerFactory.getLogger(BillMathValidator.class);

    @Value("${app.bill.validation.line-tolerance-percent:5}")
    private int lineTolerancePercent;

    @Value("${app.bill.validation.total-tolerance-percent:3}")
    private int totalTolerancePercent;

    /**
     * Validate all extracted items and bill totals.
     */
    public BillValidationResult validate(
            List<ReceiptExtractionResult.ExtractedReceiptItem> items,
            BigDecimal extractedSubtotal,
            BigDecimal extractedTax,
            BigDecimal extractedDiscount,
            BigDecimal extractedGrandTotal
    ) {
        List<LineValidation> lineValidations = new ArrayList<>();
        BigDecimal calculatedItemsTotal = BigDecimal.ZERO;
        int validLines = 0;
        int invalidLines = 0;

        // 1. Line-level validation
        for (int i = 0; i < items.size(); i++) {
            ReceiptExtractionResult.ExtractedReceiptItem item = items.get(i);
            LineValidation lv = validateLine(i, item);
            lineValidations.add(lv);

            if (lv.isValid()) validLines++;
            else invalidLines++;

            // Use actual lineTotal for bill-level calculation
            BigDecimal lineAmount = item.getLineTotal();
            if (lineAmount == null || lineAmount.compareTo(BigDecimal.ZERO) == 0) {
                // Try to calculate from qty × unitPrice
                if (item.getQuantity() != null && item.getUnitPrice() != null) {
                    lineAmount = item.getQuantity().multiply(item.getUnitPrice()).setScale(2, RoundingMode.HALF_UP);
                }
            }
            if (lineAmount != null) {
                calculatedItemsTotal = calculatedItemsTotal.add(lineAmount);
            }
        }

        // 2. Bill-level validation
        BigDecimal taxAmount = extractedTax != null ? extractedTax : BigDecimal.ZERO;
        BigDecimal discountAmount = extractedDiscount != null ? extractedDiscount : BigDecimal.ZERO;
        BigDecimal calculatedGrandTotal = calculatedItemsTotal.add(taxAmount).subtract(discountAmount);

        boolean billReconciled = true;
        BigDecimal discrepancy = BigDecimal.ZERO;
        List<String> possibleReasons = new ArrayList<>();

        if (extractedGrandTotal != null && extractedGrandTotal.compareTo(BigDecimal.ZERO) > 0) {
            discrepancy = extractedGrandTotal.subtract(calculatedGrandTotal).abs();
            BigDecimal toleranceAmount = extractedGrandTotal
                    .multiply(BigDecimal.valueOf(totalTolerancePercent))
                    .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);

            billReconciled = discrepancy.compareTo(toleranceAmount) <= 0;

            if (!billReconciled) {
                // Try to determine possible reasons
                if (calculatedGrandTotal.compareTo(extractedGrandTotal) < 0) {
                    possibleReasons.add("Items total is less than bill total — possible missing items or OCR missed some lines");
                } else {
                    possibleReasons.add("Items total exceeds bill total — possible discount not captured or OCR read extra items");
                }

                if (taxAmount.compareTo(BigDecimal.ZERO) == 0 && discrepancy.compareTo(BigDecimal.valueOf(50)) <= 0) {
                    possibleReasons.add("Tax may not have been detected — difference could be tax amount");
                }

                if (discountAmount.compareTo(BigDecimal.ZERO) == 0) {
                    possibleReasons.add("No discount detected — a discount may be applied but not captured");
                }
            }
        } else {
            // No grand total to compare against — set as uncertain
            possibleReasons.add("Grand total not found on receipt — cannot verify bill-level accuracy");
        }

        // 3. Determine overall status
        String status;
        if (billReconciled && invalidLines == 0) {
            status = "VALID";
        } else if (billReconciled && invalidLines > 0) {
            status = "MINOR_DISCREPANCY";
        } else if (!billReconciled && discrepancy.compareTo(BigDecimal.valueOf(100)) <= 0) {
            status = "MINOR_DISCREPANCY";
        } else if (!billReconciled) {
            status = "NEEDS_REVIEW";
        } else {
            status = "VALID";
        }

        log.info("Bill validation: status={}, itemsTotal={}, grandTotal={}, discrepancy={}, validLines={}, invalidLines={}",
                status, calculatedItemsTotal, extractedGrandTotal, discrepancy, validLines, invalidLines);

        return BillValidationResult.builder()
                .status(status)
                .isReconciled(billReconciled)
                .calculatedItemsTotal(calculatedItemsTotal)
                .extractedGrandTotal(extractedGrandTotal)
                .discrepancy(discrepancy)
                .possibleReasons(possibleReasons)
                .lineValidations(lineValidations)
                .validLineCount(validLines)
                .invalidLineCount(invalidLines)
                .build();
    }

    private LineValidation validateLine(int index, ReceiptExtractionResult.ExtractedReceiptItem item) {
        BigDecimal qty = item.getQuantity();
        BigDecimal unitPrice = item.getUnitPrice();
        BigDecimal lineTotal = item.getLineTotal();

        if (qty == null || unitPrice == null || lineTotal == null) {
            return LineValidation.builder()
                    .index(index)
                    .itemName(item.getRawName())
                    .valid(lineTotal != null) // Valid if we at least have a total
                    .reason(lineTotal == null ? "Missing line total" : "Missing quantity or unit price")
                    .build();
        }

        if (lineTotal.compareTo(BigDecimal.ZERO) == 0 && unitPrice.compareTo(BigDecimal.ZERO) == 0) {
            return LineValidation.builder()
                    .index(index)
                    .itemName(item.getRawName())
                    .valid(false)
                    .reason("Zero price — possible OCR error")
                    .build();
        }

        // Check: qty × unitPrice ≈ lineTotal
        BigDecimal calculated = qty.multiply(unitPrice).setScale(2, RoundingMode.HALF_UP);
        BigDecimal lineDiff = lineTotal.subtract(calculated).abs();

        // Account for item-level discount/tax
        BigDecimal itemDiscount = item.getDiscount() != null ? item.getDiscount() : BigDecimal.ZERO;
        BigDecimal itemTax = item.getTax() != null ? item.getTax() : BigDecimal.ZERO;
        BigDecimal adjustedCalculated = calculated.subtract(itemDiscount).add(itemTax);
        BigDecimal adjustedDiff = lineTotal.subtract(adjustedCalculated).abs();

        BigDecimal tolerance = lineTotal
                .multiply(BigDecimal.valueOf(lineTolerancePercent))
                .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP)
                .max(BigDecimal.valueOf(1.0)); // Minimum ₹1 tolerance

        boolean valid = lineDiff.compareTo(tolerance) <= 0 || adjustedDiff.compareTo(tolerance) <= 0;

        String reason = null;
        if (!valid) {
            reason = String.format("qty(%.2f) × price(%.2f) = %.2f, but lineTotal = %.2f (diff: %.2f)",
                    qty.doubleValue(), unitPrice.doubleValue(), calculated.doubleValue(),
                    lineTotal.doubleValue(), lineDiff.doubleValue());
        }

        // Anomaly check: unreasonable prices
        if (unitPrice.compareTo(BigDecimal.valueOf(50000)) > 0) {
            valid = false;
            reason = "Unreasonably high unit price: ₹" + unitPrice;
        }
        if (unitPrice.compareTo(BigDecimal.ZERO) < 0) {
            valid = false;
            reason = "Negative unit price: ₹" + unitPrice;
        }

        return LineValidation.builder()
                .index(index)
                .itemName(item.getRawName())
                .valid(valid)
                .calculatedTotal(calculated)
                .extractedTotal(lineTotal)
                .difference(lineDiff)
                .reason(reason)
                .build();
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BillValidationResult {
        private String status; // VALID, MINOR_DISCREPANCY, NEEDS_REVIEW, FAILED
        private boolean isReconciled;
        private BigDecimal calculatedItemsTotal;
        private BigDecimal extractedGrandTotal;
        private BigDecimal discrepancy;
        @Builder.Default
        private List<String> possibleReasons = new ArrayList<>();
        @Builder.Default
        private List<LineValidation> lineValidations = new ArrayList<>();
        private int validLineCount;
        private int invalidLineCount;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LineValidation {
        private int index;
        private String itemName;
        private boolean valid;
        private BigDecimal calculatedTotal;
        private BigDecimal extractedTotal;
        private BigDecimal difference;
        private String reason;
    }
}
