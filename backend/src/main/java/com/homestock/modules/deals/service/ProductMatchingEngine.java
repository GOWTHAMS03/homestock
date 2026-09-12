package com.homestock.modules.deals.service;

import com.homestock.modules.deals.model.*;
import com.homestock.modules.smartshopping.engine.matching.FuzzySimilarityEngine;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * Product Matching Engine (Phases 3 & 4).
 * Evaluates candidate products against the requested product intent using configurable weighted signals
 * and enforces strict Exact Match vs Similar/Alternative segregation.
 */
@Service("dealProductMatchingEngine")
@RequiredArgsConstructor
public class ProductMatchingEngine {

    private static final Logger log = LoggerFactory.getLogger(ProductMatchingEngine.class);

    private final FuzzySimilarityEngine fuzzyEngine;

    @Value("${deals.matching.weight.product-name:0.30}")
    private double weightProductName = 0.30;

    @Value("${deals.matching.weight.brand:0.20}")
    private double weightBrand = 0.20;

    @Value("${deals.matching.weight.category:0.10}")
    private double weightCategory = 0.10;

    @Value("${deals.matching.weight.quantity:0.15}")
    private double weightQuantity = 0.15;

    @Value("${deals.matching.weight.variant:0.10}")
    private double weightVariant = 0.10;

    @Value("${deals.matching.weight.pack-size:0.05}")
    private double weightPackSize = 0.05;

    @Value("${deals.matching.weight.availability:0.05}")
    private double weightAvailability = 0.05;

    @Value("${deals.matching.weight.data-confidence:0.05}")
    private double weightDataConfidence = 0.05;

    @Value("${deals.matching.exact-threshold:0.80}")
    private double exactMatchThreshold = 0.80;

    @Value("${deals.matching.alternative-threshold:0.50}")
    private double alternativeThreshold = 0.50;

    public ProductMatchResult match(NormalizedProductQuery requested, DealCandidateInput candidate) {
        if (requested == null || candidate == null) {
            return ProductMatchResult.rejected("Missing query or candidate", List.of());
        }

        List<MatchSignal> signals = new ArrayList<>();

        // 1. Product name similarity
        double nameScore = computeNameScore(requested, candidate);
        signals.add(MatchSignal.builder()
                .name("product_name")
                .weight(weightProductName)
                .score(nameScore)
                .passed(nameScore >= 0.60)
                .detail(String.format("Name similarity: %.2f", nameScore))
                .build());

        // 2. Brand match
        BrandScore brandResult = computeBrandScore(requested.getBrand(), candidate.getBrand(), candidate.getTitle());
        signals.add(MatchSignal.builder()
                .name("brand")
                .weight(weightBrand)
                .score(brandResult.score)
                .passed(brandResult.isMatch)
                .detail(brandResult.detail)
                .build());

        // 3. Category match
        double categoryScore = computeCategoryScore(requested.getCategory(), candidate.getCategory(), candidate.getTitle());
        signals.add(MatchSignal.builder()
                .name("category")
                .weight(weightCategory)
                .score(categoryScore)
                .passed(categoryScore >= 0.70)
                .detail(String.format("Category match: %.2f", categoryScore))
                .build());

        // 4. Quantity match (Strict: Fortune 1L vs 5L must fail exact match)
        QuantityScore qtyResult = computeQuantityScore(requested, candidate);
        signals.add(MatchSignal.builder()
                .name("quantity")
                .weight(weightQuantity)
                .score(qtyResult.score)
                .passed(qtyResult.isStrictMatch)
                .detail(qtyResult.detail)
                .build());

        // 5. Variant match (Strict: Sunflower vs Rice Bran must fail exact match)
        VariantScore variantResult = computeVariantScore(requested.getVariant(), candidate.getVariant(), candidate.getTitle());
        signals.add(MatchSignal.builder()
                .name("variant")
                .weight(weightVariant)
                .score(variantResult.score)
                .passed(variantResult.isStrictMatch)
                .detail(variantResult.detail)
                .build());

        // 6. Pack count match (Strict: 2x1L Combo vs 1L must fail exact match)
        boolean packCountMatches = requested.getPackCount() == null
                || candidate.getPackCount() == null
                || requested.getPackCount().equals(candidate.getPackCount());
        double packScore = packCountMatches ? 1.0 : 0.0;
        signals.add(MatchSignal.builder()
                .name("pack_size")
                .weight(weightPackSize)
                .score(packScore)
                .passed(packCountMatches)
                .detail(packCountMatches ? "Pack count matches" : "Pack count mismatch: requested " + requested.getPackCount() + " vs candidate " + candidate.getPackCount())
                .build());

        // 7. Availability match
        boolean inStock = isCandidateInStock(candidate.getAvailability());
        double availScore = inStock ? 1.0 : 0.0;
        signals.add(MatchSignal.builder()
                .name("availability")
                .weight(weightAvailability)
                .score(availScore)
                .passed(inStock)
                .detail(inStock ? "In stock" : "Out of stock / unavailable")
                .build());

        // 8. Data confidence
        double confidence = candidate.getConfidence() != null ? candidate.getConfidence() : 0.90;
        signals.add(MatchSignal.builder()
                .name("data_confidence")
                .weight(weightDataConfidence)
                .score(confidence)
                .passed(confidence >= 0.70)
                .detail(String.format("Confidence: %.2f", confidence))
                .build());

        // Compute total weighted match score
        double totalWeightedScore = 0.0;
        for (MatchSignal s : signals) {
            totalWeightedScore += s.getWeightedContribution();
        }

        // --- STRICT EXACT MATCH RULES EVALUATION (Phase 4) ---
        // Rule A: Quantity mismatch strictly blocks exact match (e.g. 5L for 1L)
        if (requested.getCanonicalQuantity() != null && !qtyResult.isStrictMatch) {
            return ProductMatchResult.builder()
                    .exactMatch(false)
                    .matchScore(totalWeightedScore)
                    .category(DealMatchCategory.REJECTED)
                    .reason("Strict rejection: Quantity mismatch (" + qtyResult.detail + ")")
                    .signals(signals)
                    .build();
        }

        // Rule B: Pack count mismatch strictly blocks exact match (e.g. 2x1L combo for 1L)
        if (!packCountMatches) {
            return ProductMatchResult.builder()
                    .exactMatch(false)
                    .matchScore(totalWeightedScore)
                    .category(DealMatchCategory.REJECTED)
                    .reason("Strict rejection: Pack count combo mismatch")
                    .signals(signals)
                    .build();
        }

        // Rule C: Variant conflict strictly blocks exact match (e.g. Rice Bran for Sunflower)
        if (requested.getVariant() != null && variantResult.hasConflict) {
            return ProductMatchResult.builder()
                    .exactMatch(false)
                    .matchScore(totalWeightedScore)
                    .category(DealMatchCategory.REJECTED)
                    .reason("Strict rejection: Variant conflict (" + variantResult.detail + ")")
                    .signals(signals)
                    .build();
        }

        // Rule D: Brand mismatch (e.g. Saffola when Fortune was requested)
        // May qualify as SIMILAR_ALTERNATIVE, but NEVER as EXACT_MATCH!
        if (requested.getBrand() != null && !brandResult.isMatch) {
            if (totalWeightedScore >= alternativeThreshold && categoryScore >= 0.70) {
                return ProductMatchResult.builder()
                        .exactMatch(false)
                        .matchScore(totalWeightedScore)
                        .category(DealMatchCategory.SIMILAR_ALTERNATIVE)
                        .reason("Similar / Alternative product (Different brand: " + candidate.getBrand() + " vs requested " + requested.getBrand() + ")")
                        .signals(signals)
                        .build();
            } else {
                return ProductMatchResult.builder()
                        .exactMatch(false)
                        .matchScore(totalWeightedScore)
                        .category(DealMatchCategory.REJECTED)
                        .reason("Rejected: Brand mismatch and low alternative score")
                        .signals(signals)
                        .build();
            }
        }

        // Rule E: Exact match qualification
        if (totalWeightedScore >= exactMatchThreshold && inStock) {
            return ProductMatchResult.builder()
                    .exactMatch(true)
                    .matchScore(totalWeightedScore)
                    .category(DealMatchCategory.EXACT_MATCH)
                    .reason("Verified Exact Match")
                    .signals(signals)
                    .build();
        }

        // Rule F: Borderline / similar qualification
        if (totalWeightedScore >= alternativeThreshold) {
            return ProductMatchResult.builder()
                    .exactMatch(false)
                    .matchScore(totalWeightedScore)
                    .category(DealMatchCategory.SIMILAR_ALTERNATIVE)
                    .reason("Alternative product candidate")
                    .signals(signals)
                    .build();
        }

        return ProductMatchResult.builder()
                .exactMatch(false)
                .matchScore(totalWeightedScore)
                .category(DealMatchCategory.REJECTED)
                .reason("Score below qualification threshold (" + String.format("%.2f", totalWeightedScore) + ")")
                .signals(signals)
                .build();
    }

    private double computeNameScore(NormalizedProductQuery requested, DealCandidateInput candidate) {
        String req = requested.getProduct() != null ? requested.getProduct() : requested.getNormalizedQuery();
        String cand = candidate.getTitle();
        if (cand == null || cand.isBlank()) return 0.0;
        if (req == null || req.isBlank()) return 0.70;

        double sim = fuzzyEngine != null ? fuzzyEngine.tokenSortRatio(req, cand) : 0.5;
        // Jaro-Winkler bonus if exact phrase match
        if (cand.toLowerCase().contains(req.toLowerCase())) {
            sim = Math.max(sim, 0.90);
        }
        return Math.min(1.0, Math.max(0.0, sim));
    }

    private BrandScore computeBrandScore(String reqBrand, String candBrand, String title) {
        if (reqBrand == null || reqBrand.isBlank()) {
            return new BrandScore(1.0, true, "No brand requested (wildcard)");
        }
        String cleanReq = reqBrand.trim().toLowerCase();

        // 1. Direct candidate brand field
        if (candBrand != null && !candBrand.isBlank()) {
            String cleanCand = candBrand.trim().toLowerCase();
            if (cleanReq.equals(cleanCand)) {
                return new BrandScore(1.0, true, "Exact brand match");
            }
            double sim = fuzzyEngine != null ? fuzzyEngine.jaroWinkler(cleanReq, cleanCand) : 0.0;
            if (sim >= 0.88) {
                return new BrandScore(sim, true, "Fuzzy brand match (" + candBrand + ")");
            }
        }

        // 2. Title inspection for brand
        if (title != null) {
            String cleanTitle = title.toLowerCase();
            if (cleanTitle.contains(cleanReq)) {
                return new BrandScore(0.95, true, "Brand present in title");
            }
        }

        return new BrandScore(0.0, false, "Brand mismatch (requested: " + reqBrand + ")");
    }

    private double computeCategoryScore(String reqCat, String candCat, String title) {
        if (reqCat == null || reqCat.isBlank()) return 0.80;
        if (candCat != null && candCat.equalsIgnoreCase(reqCat)) return 1.0;
        if (title != null && title.toLowerCase().contains(reqCat.toLowerCase())) return 0.90;
        if (reqCat.equalsIgnoreCase("Cooking Oil") && title != null && title.toLowerCase().contains("oil")) return 0.90;
        return 0.50;
    }

    private QuantityScore computeQuantityScore(NormalizedProductQuery requested, DealCandidateInput candidate) {
        if (requested.getCanonicalQuantity() == null) {
            return new QuantityScore(0.85, true, "No quantity requested");
        }
        if (candidate.getQuantity() == null) {
            // Try to extract quantity from title
            return new QuantityScore(0.50, false, "Candidate quantity not specified");
        }

        BigDecimal reqQty = requested.getCanonicalQuantity();
        BigDecimal candQty = candidate.getQuantity();

        // Check unit alignment (e.g. ML vs ML or G vs G)
        if (requested.getCanonicalUnit() != null && candidate.getUnit() != null) {
            String u1 = requested.getCanonicalUnit().toUpperCase();
            String u2 = candidate.getUnit().toUpperCase();
            if (u1.equals("ML") && (u2.equals("L") || u2.equals("LTR") || u2.equals("LITRE"))) {
                candQty = candQty.multiply(new BigDecimal("1000"));
            } else if (u1.equals("G") && (u2.equals("KG") || u2.equals("KGS") || u2.equals("KILO"))) {
                candQty = candQty.multiply(new BigDecimal("1000"));
            }
        }

        // Ratio difference
        double diff = Math.abs(reqQty.doubleValue() - candQty.doubleValue());
        double relativeDiff = diff / reqQty.doubleValue();

        if (relativeDiff <= 0.02) { // within 2%
            return new QuantityScore(1.0, true, "Exact quantity match: " + reqQty.stripTrailingZeros() + " " + requested.getCanonicalUnit());
        }

        return new QuantityScore(0.0, false, String.format("Quantity mismatch: requested %.0f %s, candidate %.0f",
                reqQty.doubleValue(), requested.getCanonicalUnit(), candQty.doubleValue()));
    }

    private VariantScore computeVariantScore(String reqVariant, String candVariant, String title) {
        if (reqVariant == null || reqVariant.isBlank()) {
            return new VariantScore(1.0, true, false, "No variant requested");
        }
        String cleanReq = reqVariant.toLowerCase().trim();

        if (candVariant != null && !candVariant.isBlank()) {
            String cleanCand = candVariant.toLowerCase().trim();
            if (cleanCand.equals(cleanReq)) {
                return new VariantScore(1.0, true, false, "Exact variant match");
            }
            if (!cleanCand.contains(cleanReq)) {
                return new VariantScore(0.0, false, true, "Conflicting variant: " + candVariant);
            }
        }

        if (title != null) {
            String cleanTitle = title.toLowerCase();
            if (cleanTitle.contains(cleanReq)) {
                return new VariantScore(1.0, true, false, "Variant found in title");
            }
            // Check for known conflicting oil variants
            String[] commonVariants = {"sunflower", "rice bran", "mustard", "groundnut", "soybean", "olive"};
            for (String v : commonVariants) {
                if (!v.equals(cleanReq) && cleanTitle.contains(v)) {
                    return new VariantScore(0.0, false, true, "Conflicting variant in title: " + v);
                }
            }
        }

        return new VariantScore(0.40, false, false, "Variant unconfirmed");
    }

    private boolean isCandidateInStock(String availability) {
        if (availability == null || availability.isBlank()) return true;
        String clean = availability.toUpperCase();
        return clean.contains("IN_STOCK") || clean.contains("AVAILABLE") || clean.contains("IN STOCK");
    }

    private record BrandScore(double score, boolean isMatch, String detail) {}
    private record QuantityScore(double score, boolean isStrictMatch, String detail) {}
    private record VariantScore(double score, boolean isStrictMatch, boolean hasConflict, String detail) {}
}
