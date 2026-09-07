package com.homestock.modules.smartshopping.service;

import com.homestock.modules.smartshopping.dto.ProductOfferDto;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

/**
 * Confidence-based product matching service.
 * <p>
 * Prevents incorrect comparisons (e.g. 5kg Rice vs 1kg Rice) by scoring
 * product similarity across multiple dimensions: brand, name, package size, and category.
 */
@Service
@RequiredArgsConstructor
public class ProductMatchingService {

    private static final Logger log = LoggerFactory.getLogger(ProductMatchingService.class);

    private final UnitNormalizationService unitService;

    @Value("${app.smart-shopping.matching.confidence-threshold:0.75}")
    private double confidenceThreshold;

    private static final double WEIGHT_BRAND = 0.25;
    private static final double WEIGHT_NAME = 0.35;
    private static final double WEIGHT_SIZE = 0.30;
    private static final double WEIGHT_CATEGORY = 0.10;

    /**
     * Calculate match confidence between a shopping item and a product offer.
     *
     * @param itemName      shopping list item name
     * @param itemBrand     shopping list item brand (nullable)
     * @param itemQuantity  desired quantity
     * @param itemUnit      desired unit
     * @param itemCategory  item category (nullable)
     * @param offer         the product offer to compare against
     * @return match result with confidence score and type
     */
    public MatchResult calculateMatch(
            String itemName,
            String itemBrand,
            BigDecimal itemQuantity,
            String itemUnit,
            String itemCategory,
            ProductOfferDto offer
    ) {
        double brandScore = scoreBrand(itemBrand, offer.getBrand());
        double nameScore = scoreName(itemName, offer.getProductName());
        double sizeScore = scoreSize(itemQuantity, itemUnit, offer.getPackageSize(), offer.getUnit());
        double categoryScore = scoreCategory(itemCategory, offer.getProductName());

        double totalConfidence =
                (brandScore * WEIGHT_BRAND) +
                (nameScore * WEIGHT_NAME) +
                (sizeScore * WEIGHT_SIZE) +
                (categoryScore * WEIGHT_CATEGORY);

        // Clamp to [0, 1]
        totalConfidence = Math.max(0.0, Math.min(1.0, totalConfidence));

        String matchType;
        if (totalConfidence >= 0.90) {
            matchType = "EXACT";
        } else if (totalConfidence >= confidenceThreshold) {
            matchType = "SIMILAR";
        } else {
            matchType = "NO_MATCH";
        }

        log.debug("[ProductMatching] '{}' vs '{}' — brand={:.2f} name={:.2f} size={:.2f} cat={:.2f} → total={:.3f} ({})",
                itemName, offer.getProductName(), brandScore, nameScore, sizeScore, categoryScore, totalConfidence, matchType);

        return new MatchResult(totalConfidence, matchType, totalConfidence >= confidenceThreshold);
    }

    /**
     * Apply match results to an offer, enriching it with confidence data.
     */
    public ProductOfferDto enrichWithMatch(ProductOfferDto offer, MatchResult match) {
        offer.setMatchConfidence(match.confidence());
        offer.setMatchType(match.matchType());
        return offer;
    }

    // ──── Scoring Functions ────

    private double scoreBrand(String itemBrand, String offerBrand) {
        if (itemBrand == null || itemBrand.isBlank()) return 0.5; // Neutral if no brand specified
        if (offerBrand == null || offerBrand.isBlank()) return 0.3;

        String a = itemBrand.toLowerCase().trim();
        String b = offerBrand.toLowerCase().trim();

        if (a.equals(b)) return 1.0;
        if (a.contains(b) || b.contains(a)) return 0.8;

        return jaroWinklerSimilarity(a, b);
    }

    private double scoreName(String itemName, String offerName) {
        if (itemName == null || offerName == null) return 0.0;

        String a = itemName.toLowerCase().trim();
        String b = offerName.toLowerCase().trim();

        if (a.equals(b)) return 1.0;
        if (b.contains(a) || a.contains(b)) return 0.85;

        // Word overlap scoring
        String[] aWords = a.split("\\s+");
        String[] bWords = b.split("\\s+");

        int matchedWords = 0;
        for (String aw : aWords) {
            if (aw.length() < 2) continue; // Skip tiny words
            for (String bw : bWords) {
                if (aw.equals(bw) || aw.contains(bw) || bw.contains(aw)) {
                    matchedWords++;
                    break;
                }
            }
        }

        int significantWords = (int) java.util.Arrays.stream(aWords).filter(w -> w.length() >= 2).count();
        if (significantWords == 0) return 0.3;

        double wordOverlap = (double) matchedWords / significantWords;

        // Blend word overlap with Jaro-Winkler
        double jw = jaroWinklerSimilarity(a, b);
        return (wordOverlap * 0.6) + (jw * 0.4);
    }

    private double scoreSize(BigDecimal itemQty, String itemUnit, String offerPackageSize, String offerUnit) {
        if (itemQty == null || itemUnit == null) return 0.5; // Neutral

        // Parse offer's package size
        BigDecimal offerQty = null;
        String offerUnitResolved = offerUnit;

        if (offerPackageSize != null) {
            UnitNormalizationService.PackageSize parsed = unitService.parsePackageSize(offerPackageSize);
            if (parsed != null) {
                offerQty = parsed.quantity();
                offerUnitResolved = parsed.unit();
            } else {
                try {
                    offerQty = new BigDecimal(offerPackageSize.trim());
                } catch (NumberFormatException ignored) {}
            }
        }

        if (offerQty == null || offerUnitResolved == null) return 0.3;

        // Check if units are comparable
        if (!unitService.areUnitsComparable(itemUnit, offerUnitResolved)) {
            return 0.1; // Incompatible units
        }

        // Normalize both to base units
        UnitNormalizationService.NormalizedUnit itemNorm = unitService.normalize(itemQty, itemUnit);
        UnitNormalizationService.NormalizedUnit offerNorm = unitService.normalize(offerQty, offerUnitResolved);

        // Compare quantities — exact match = 1.0, close = partial score
        double ratio;
        if (itemNorm.quantity().compareTo(BigDecimal.ZERO) == 0) return 0.3;
        ratio = offerNorm.quantity().doubleValue() / itemNorm.quantity().doubleValue();

        if (Math.abs(ratio - 1.0) < 0.01) return 1.0;      // Exact match
        if (ratio >= 0.8 && ratio <= 1.2) return 0.7;        // Close enough
        if (ratio >= 0.5 && ratio <= 2.0) return 0.4;        // Different size but same unit family
        return 0.1;                                            // Very different size
    }

    private double scoreCategory(String itemCategory, String offerName) {
        if (itemCategory == null || offerName == null) return 0.5; // Neutral

        String cat = itemCategory.toLowerCase().trim();
        String name = offerName.toLowerCase().trim();

        // Simple heuristic: does the product name contain category-related words?
        if (name.contains(cat)) return 1.0;

        return 0.5; // Default neutral
    }

    // ──── String Similarity ────

    /**
     * Jaro-Winkler similarity between two strings.
     * Returns a value between 0.0 (no similarity) and 1.0 (exact match).
     */
    private double jaroWinklerSimilarity(String s1, String s2) {
        if (s1 == null || s2 == null) return 0.0;
        if (s1.equals(s2)) return 1.0;
        if (s1.isEmpty() || s2.isEmpty()) return 0.0;

        int maxLen = Math.max(s1.length(), s2.length());
        int matchWindow = Math.max(maxLen / 2 - 1, 0);

        boolean[] s1Matches = new boolean[s1.length()];
        boolean[] s2Matches = new boolean[s2.length()];

        int matches = 0;
        int transpositions = 0;

        for (int i = 0; i < s1.length(); i++) {
            int start = Math.max(0, i - matchWindow);
            int end = Math.min(i + matchWindow + 1, s2.length());

            for (int j = start; j < end; j++) {
                if (s2Matches[j] || s1.charAt(i) != s2.charAt(j)) continue;
                s1Matches[i] = true;
                s2Matches[j] = true;
                matches++;
                break;
            }
        }

        if (matches == 0) return 0.0;

        int k = 0;
        for (int i = 0; i < s1.length(); i++) {
            if (!s1Matches[i]) continue;
            while (!s2Matches[k]) k++;
            if (s1.charAt(i) != s2.charAt(k)) transpositions++;
            k++;
        }

        double jaro = ((double) matches / s1.length()
                + (double) matches / s2.length()
                + (double) (matches - transpositions / 2.0) / matches) / 3.0;

        // Winkler prefix bonus
        int prefix = 0;
        for (int i = 0; i < Math.min(4, Math.min(s1.length(), s2.length())); i++) {
            if (s1.charAt(i) == s2.charAt(i)) prefix++;
            else break;
        }

        return jaro + prefix * 0.1 * (1.0 - jaro);
    }

    // ──── Result ────

    public record MatchResult(double confidence, String matchType, boolean isAcceptableMatch) {}
}
