package com.homestock.modules.smartshopping.engine.matching;

import com.homestock.modules.smartshopping.dto.*;
import com.homestock.modules.smartshopping.engine.identity.BrandResolver;
import com.homestock.modules.smartshopping.engine.identity.ProductAttributeExtractor;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/**
 * Evidence Scorer:
 * Computes multi-signal weighted evidence score, source consensus bonus,
 * and builds transparent, explainable DealEvidence for each candidate.
 */
@Component
@RequiredArgsConstructor
public class EvidenceScorer {

    private final FuzzySimilarityEngine fuzzyEngine;
    private final BrandResolver brandResolver;
    private final ProductAttributeExtractor attributeExtractor;

    public record ScoredEvidence(double confidence, MatchStatus status, DealEvidence evidence) {}

    /**
     * Scores a candidate against the canonical ProductIdentity and source consensus count.
     */
    public ScoredEvidence score(ProductIdentity identity, ProductCandidate candidate, int sourceAgreementCount) {
        String candTitle = candidate.getProductName() != null ? candidate.getProductName() : "";
        ProductAttributeExtractor.ExtractedAttributes candAttrs = attributeExtractor.extract(candTitle, candidate.getBarcode());

        // 1. Barcode check
        if (identity.getBarcode() != null && !identity.getBarcode().isBlank()) {
            String candBarcode = candidate.getBarcode() != null ? candidate.getBarcode() : candAttrs.getBarcode();
            if (candBarcode != null && candBarcode.trim().equalsIgnoreCase(identity.getBarcode().trim())) {
                DealEvidence ev = DealEvidence.builder()
                        .brandEvidence("Exact barcode match (" + identity.getBarcode() + ")")
                        .productEvidence("Barcode verified identity")
                        .packSizeEvidence("Canonical pack verified")
                        .priceEvidence("Valid price (₹" + candidate.getPrice() + ")")
                        .imageEvidence(candidate.getImageUrl() != null ? "Product image present" : "No image")
                        .sourceAgreement(Math.max(1, sourceAgreementCount))
                        .identityConfidence(1.0)
                        .priceConfidence(1.0)
                        .imageConfidence(candidate.getImageUrl() != null ? 1.0 : 0.5)
                        .build();
                return new ScoredEvidence(1.0, MatchStatus.VERIFIED_EXACT, ev);
            }
        }

        double totalScore = 0.0;
        double maxScore = 0.0;

        // 2. Brand Scoring (Weight: 30)
        maxScore += 30.0;
        double brandScore = 0.0;
        String brandEv;
        if (identity.getBrand() != null) {
            String reqBrand = identity.getBrand();
            String candBrand = candidate.getBrand() != null ? candidate.getBrand() : candAttrs.getBrand();
            if (candBrand != null && brandResolver.normalizeBrand(candBrand).equalsIgnoreCase(brandResolver.normalizeBrand(reqBrand))) {
                brandScore = 30.0;
                brandEv = "Exact brand match (" + reqBrand + ")";
            } else if (brandResolver.containsBrand(candTitle, reqBrand)) {
                brandScore = 28.0;
                brandEv = "Brand found in title (" + reqBrand + ")";
            } else {
                double jw = fuzzyEngine.jaroWinkler(reqBrand, candBrand != null ? candBrand : candTitle);
                brandScore = 30.0 * jw;
                brandEv = "Fuzzy brand similarity (" + String.format("%.2f", jw) + ")";
            }
        } else {
            // Generic query without requested brand
            brandScore = 20.0;
            brandEv = "Generic search - brand not restricted";
        }
        totalScore += brandScore;

        // 3. Product Name Similarity (Weight: 30)
        maxScore += 30.0;
        String reqProd = identity.getProduct() != null ? identity.getProduct() : identity.getGenericName();
        double nameSim = fuzzyEngine.combinedSimilarity(reqProd != null ? reqProd : "", candTitle);
        double nameScore = 30.0 * nameSim;
        totalScore += nameScore;
        String prodEv = "Product name match similarity: " + String.format("%.0f%%", nameSim * 100);

        // 4. Variant Match (Weight: 20)
        maxScore += 20.0;
        double variantScore = 0.0;
        if (identity.getVariant() != null) {
            String reqVar = identity.getVariant().toLowerCase();
            if (candTitle.toLowerCase().contains(reqVar)) {
                variantScore = 20.0;
            } else {
                double vSim = fuzzyEngine.combinedSimilarity(reqVar, candAttrs.getVariant() != null ? candAttrs.getVariant() : candTitle);
                variantScore = 20.0 * vSim;
            }
        } else {
            variantScore = 15.0; // Not strictly constrained
        }
        totalScore += variantScore;

        // 5. Pack Size Match (Weight: 15)
        maxScore += 15.0;
        double packScore = 0.0;
        String packEv;
        if (identity.getNormalizedPackSizeValue() != null && candAttrs.getNormalizedPackSizeValue() != null) {
            if (identity.getNormalizedPackSizeUnit().equalsIgnoreCase(candAttrs.getNormalizedPackSizeUnit())) {
                double reqVal = identity.getNormalizedPackSizeValue().doubleValue();
                double candVal = candAttrs.getNormalizedPackSizeValue();
                double diff = Math.abs(reqVal - candVal);
                if (diff == 0.0) {
                    packScore = 15.0;
                    packEv = "Exact pack size match (" + identity.getPackSize() + ")";
                } else {
                    double ratio = diff / reqVal;
                    packScore = Math.max(0.0, 15.0 * (1.0 - ratio));
                    packEv = "Pack size close (" + candAttrs.getPackSize() + " vs " + identity.getPackSize() + ")";
                }
            } else {
                packScore = 0.0;
                packEv = "Pack unit mismatch (" + candAttrs.getNormalizedPackSizeUnit() + ")";
            }
        } else if (identity.getNormalizedPackSizeValue() == null) {
            packScore = 12.0;
            packEv = "Pack size not specified";
        } else {
            packScore = 5.0;
            packEv = "Candidate pack size unverified";
        }
        totalScore += packScore;

        // 6. Category Match (Weight: 10)
        maxScore += 10.0;
        double catScore = 0.0;
        if (identity.getCategory() != null && candAttrs.getCategory() != null) {
            if (identity.getCategory().equalsIgnoreCase(candAttrs.getCategory())) {
                catScore = 10.0;
            } else {
                catScore = 5.0;
            }
        } else {
            catScore = 8.0;
        }
        totalScore += catScore;

        // 7. Image Presence (Weight: 5)
        maxScore += 5.0;
        boolean hasImg = candidate.getImageUrl() != null && !candidate.getImageUrl().isBlank();
        if (hasImg) {
            totalScore += 5.0;
        }

        // 8. Source Agreement Bonus (Up to +10 bonus points)
        double agreementBonus = Math.min(10.0, (sourceAgreementCount - 1) * 3.5);
        totalScore += agreementBonus;
        maxScore += 10.0;

        double confidence = Math.min(1.0, Math.max(0.0, totalScore / maxScore));

        MatchStatus status;
        if (confidence >= 0.90) {
            status = MatchStatus.VERIFIED_EXACT;
        } else if (confidence >= 0.80) {
            status = MatchStatus.HIGH_CONFIDENCE;
        } else if (confidence >= 0.65) {
            status = MatchStatus.POSSIBLE_MATCH;
        } else {
            status = MatchStatus.REJECT;
        }

        DealEvidence evidence = DealEvidence.builder()
                .brandEvidence(brandEv)
                .productEvidence(prodEv)
                .packSizeEvidence(packEv)
                .priceEvidence("₹" + candidate.getPrice() + (candidate.getOriginalPrice() != null ? " (MRP ₹" + candidate.getOriginalPrice() + ")" : ""))
                .imageEvidence(hasImg ? "Verified image present" : "No image")
                .sourceAgreement(Math.max(1, sourceAgreementCount))
                .identityConfidence(confidence)
                .priceConfidence(0.9)
                .imageConfidence(hasImg ? 0.9 : 0.5)
                .build();

        return new ScoredEvidence(confidence, status, evidence);
    }
}
