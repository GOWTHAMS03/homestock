package com.homestock.modules.smartshopping.engine.matching;

import com.homestock.modules.smartshopping.dto.MatchStatus;
import com.homestock.modules.smartshopping.dto.ProductCandidate;
import com.homestock.modules.smartshopping.dto.ProductIntent;
import com.homestock.modules.smartshopping.dto.SearchIntent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Product Match Engine:
 * Implements point-based match scoring with configurable weights, penalties,
 * confidence thresholds, and strict Brand Protection.
 */
@Component
public class ProductMatchEngine {

    private static final Logger log = LoggerFactory.getLogger(ProductMatchEngine.class);

    // Configurable weights (Point-based)
    @Value("${app.smart-shopping.matching.weight.barcode:100}")
    private int weightBarcode = 100;

    @Value("${app.smart-shopping.matching.weight.brand:30}")
    private int weightBrand = 30;

    @Value("${app.smart-shopping.matching.weight.product-name:30}")
    private int weightProductName = 30;

    @Value("${app.smart-shopping.matching.weight.variant:20}")
    private int weightVariant = 20;

    @Value("${app.smart-shopping.matching.weight.pack-size:15}")
    private int weightPackSize = 15;

    @Value("${app.smart-shopping.matching.weight.category:10}")
    private int weightCategory = 10;

    @Value("${app.smart-shopping.matching.weight.generic-name:10}")
    private int weightGenericName = 10;

    @Value("${app.smart-shopping.matching.weight.image:10}")
    private int weightImage = 10;

    @Value("${app.smart-shopping.matching.weight.consistency:10}")
    private int weightConsistency = 10;

    // Configurable penalties
    @Value("${app.smart-shopping.matching.penalty.wrong-brand:60}")
    private int penaltyWrongBrand = 60;

    @Value("${app.smart-shopping.matching.penalty.wrong-product:50}")
    private int penaltyWrongProduct = 50;

    @Value("${app.smart-shopping.matching.penalty.wrong-variant:30}")
    private int penaltyWrongVariant = 30;

    @Value("${app.smart-shopping.matching.penalty.wrong-pack-size:25}")
    private int penaltyWrongPackSize = 25;

    @Value("${app.smart-shopping.matching.penalty.wrong-category:50}")
    private int penaltyWrongCategory = 50;

    @Value("${app.smart-shopping.matching.penalty.missing-critical:15}")
    private int penaltyMissingCritical = 15;

    // Mutually exclusive variants
    private static final List<List<String>> VARIANT_CLASH_GROUPS = List.of(
            List.of("sunflower", "groundnut", "mustard", "olive", "sesame", "gingelly", "coconut", "palm", "rice bran", "canola"),
            List.of("basmati", "brown rice", "sona masoori", "ponni", "idli rice", "raw rice", "boiled rice"),
            List.of("toned", "double toned", "full cream", "cow milk", "skimmed"),
            List.of("zero sugar", "diet", "regular"),
            List.of("top load", "front load")
    );

    /**
     * Score a candidate against the structured ProductIntent.
     */
    public ScoredCandidate match(ProductIntent intent, ProductCandidate candidate) {
        // 1. Barcode Match: Highest Product Identity Priority
        if (intent.getBarcode() != null && !intent.getBarcode().isBlank()) {
            if (candidate.getBarcode() != null && intent.getBarcode().trim().equalsIgnoreCase(candidate.getBarcode().trim())) {
                return new ScoredCandidate(100.0, MatchStatus.VERIFIED_EXACT, true, false);
            } else if (candidate.getBarcode() != null && !candidate.getBarcode().isBlank()) {
                // Different barcode in barcode search
                return new ScoredCandidate(0.0, MatchStatus.REJECT, false, false);
            }
        }

        String reqBrand = intent.getBrand() != null ? intent.getBrand().trim().toLowerCase() : null;
        String candBrand = candidate.getBrand() != null ? candidate.getBrand().trim().toLowerCase() : null;
        String candName = candidate.getProductName() != null ? candidate.getProductName().trim().toLowerCase() : "";
        String reqVariant = intent.getVariant() != null ? intent.getVariant().trim().toLowerCase() : null;
        String reqPack = intent.getPackSize() != null ? intent.getPackSize().replaceAll("\\s+", "").toLowerCase() : null;
        String candPack = candidate.getPackageSize() != null ? candidate.getPackageSize().replaceAll("\\s+", "").toLowerCase() : null;

        int score = 0;
        boolean brandClash = false;
        boolean isExactMode = intent.getSearchIntent() == SearchIntent.EXACT_PRODUCT || intent.getSearchIntent() == SearchIntent.BRANDED_PRODUCT;

        // 2. Brand Check & Protection
        if (reqBrand != null) {
            if (candBrand != null && (candBrand.contains(reqBrand) || reqBrand.contains(candBrand) || candName.contains(reqBrand))) {
                score += weightBrand;
            } else if (candBrand != null && !candBrand.isBlank() && !candBrand.equals(reqBrand)) {
                // Severe penalty for wrong brand: Brand Protection Rule
                score -= penaltyWrongBrand;
                brandClash = true;
            } else if (!candName.contains(reqBrand)) {
                score -= penaltyMissingCritical;
            }
        } else {
            // Neutral for generic search
            score += (weightBrand / 2);
        }

        // 3. Exact Product Name Matching
        String reqProdName = intent.getProductName() != null ? intent.getProductName().toLowerCase() : "";
        if (!reqProdName.isBlank() && candName.contains(reqProdName)) {
            score += weightProductName;
        } else {
            // Check significant word overlap
            double overlap = wordOverlap(reqProdName, candName);
            if (overlap >= 0.7) {
                score += (int) (weightProductName * overlap);
            } else if (overlap < 0.3 && isExactMode) {
                score -= penaltyWrongProduct;
            }
        }

        // 4. Variant Clash & Matching
        if (reqVariant != null) {
            if (candName.contains(reqVariant)) {
                score += weightVariant;
            } else if (hasVariantClash(reqVariant, candName)) {
                score -= penaltyWrongVariant;
            }
        } else {
            score += (weightVariant / 2);
        }

        // 5. Pack Size Matching
        if (reqPack != null && candPack != null) {
            if (reqPack.equalsIgnoreCase(candPack) || candName.replaceAll("\\s+", "").contains(reqPack)) {
                score += weightPackSize;
            } else {
                // Different pack size
                score -= penaltyWrongPackSize;
            }
        } else if (reqPack == null) {
            score += (weightPackSize / 2);
        }

        // 6. Category Matching
        String reqCat = intent.getCategory() != null ? intent.getCategory().toLowerCase() : null;
        String candCat = candidate.getCategory() != null ? candidate.getCategory().toLowerCase() : null;
        if (reqCat != null && candCat != null && reqCat.contains(candCat)) {
            score += weightCategory;
        } else {
            score += (weightCategory / 2);
        }

        // 7. Generic Name Matching
        String reqGeneric = intent.getGenericName() != null ? intent.getGenericName().toLowerCase() : null;
        if (reqGeneric != null && candName.contains(reqGeneric)) {
            score += weightGenericName;
        }

        // 8. Image & Seller Title Consistency
        if (candidate.getImageUrl() != null && !candidate.getImageUrl().isBlank()) {
            score += weightImage;
        }
        score += weightConsistency;

        // Clamp raw points into percentage [0, 100]
        double finalScore = Math.max(0.0, Math.min(100.0, (double) score));

        // Brand Protection Override: If brand was specified and cand has wrong brand, never allow >= 70
        if (brandClash && isExactMode) {
            finalScore = Math.min(finalScore, 40.0);
        }

        // Classify Confidence Levels
        MatchStatus status;
        if (finalScore >= 95.0 && !brandClash) {
            status = MatchStatus.VERIFIED_EXACT;
        } else if (finalScore >= 85.0 && !brandClash) {
            status = MatchStatus.HIGH_CONFIDENCE;
        } else if (finalScore >= 70.0) {
            status = MatchStatus.POSSIBLE_MATCH;
        } else {
            status = MatchStatus.REJECT;
        }

        boolean isAcceptableExact = (status == MatchStatus.VERIFIED_EXACT || status == MatchStatus.HIGH_CONFIDENCE) && !brandClash;

        return new ScoredCandidate(finalScore, status, isAcceptableExact, brandClash);
    }

    private boolean hasVariantClash(String reqVariant, String candText) {
        String req = reqVariant.toLowerCase();
        String cand = candText.toLowerCase();

        for (List<String> group : VARIANT_CLASH_GROUPS) {
            if (group.stream().anyMatch(req::contains)) {
                for (String v : group) {
                    if (cand.contains(v) && !req.contains(v)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private double wordOverlap(String s1, String s2) {
        String[] w1 = s1.split("\\s+");
        String[] w2 = s2.split("\\s+");
        int matches = 0;
        int count = 0;
        for (String a : w1) {
            if (a.length() < 2) continue;
            count++;
            for (String b : w2) {
                if (a.equalsIgnoreCase(b) || b.contains(a)) {
                    matches++;
                    break;
                }
            }
        }
        return count == 0 ? 0.5 : (double) matches / count;
    }

    public record ScoredCandidate(double score, MatchStatus status, boolean isAcceptableExact, boolean isBrandClash) {}
}
