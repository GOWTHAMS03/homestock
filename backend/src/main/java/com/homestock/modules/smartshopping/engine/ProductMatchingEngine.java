package com.homestock.modules.smartshopping.engine;

import com.homestock.modules.smartshopping.dto.ProductOfferDto;
import com.homestock.modules.smartshopping.dto.ProductSearchIntentDto;
import com.homestock.modules.smartshopping.service.ProductMatchingService;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

/**
 * ProductMatchingEngine:
 * Filters and validates product offers against user intent.
 * - In GENERIC_DISCOVERY: Welcomes diverse variants (Sunflower, Coconut, Groundnut) while filtering out false-category noise.
 * - In EXACT_PRODUCT: Strict brand and variant clash enforcement.
 */
@Component
@RequiredArgsConstructor
public class ProductMatchingEngine {

    private static final Logger log = LoggerFactory.getLogger(ProductMatchingEngine.class);

    private final ProductMatchingService matchingService;

    // Words that indicate non-grocery or inappropriate category leak
    private static final List<String> OIL_NEGATIVE_KEYWORDS = List.of(
            "hair oil", "castor oil for hair", "motor oil", "engine oil", "essential oil", "aroma oil", "massage oil", "oil pastel"
    );

    /**
     * Filter and score candidate offers against user intent.
     */
    public List<ProductOfferDto> filterAndScore(ProductSearchIntentDto intent, List<ProductOfferDto> candidateOffers) {
        if (candidateOffers == null || candidateOffers.isEmpty()) {
            return Collections.emptyList();
        }

        boolean isExactMode = "EXACT_PRODUCT".equalsIgnoreCase(intent.getSearchMode());
        List<ProductOfferDto> matched = new ArrayList<>();

        for (ProductOfferDto offer : candidateOffers) {
            String nameLower = offer.getProductName() != null ? offer.getProductName().toLowerCase() : "";
            String brandLower = offer.getBrand() != null ? offer.getBrand().toLowerCase() : "";

            // 1. Negative keyword filter for cooking oil
            if ("Cooking Oil".equalsIgnoreCase(intent.getPrimaryCategory())) {
                boolean hasNegative = OIL_NEGATIVE_KEYWORDS.stream().anyMatch(nameLower::contains);
                if (hasNegative) {
                    log.debug("[ProductMatchingEngine] Excluded non-edible oil: {}", offer.getProductName());
                    continue;
                }
            }

            // 2. Barcode exact matching
            if (intent.getTargetBarcode() != null && !intent.getTargetBarcode().isBlank()) {
                if (offer.getBarcode() != null && intent.getTargetBarcode().equalsIgnoreCase(offer.getBarcode().trim())) {
                    offer.setMatchConfidence(1.0);
                    offer.setMatchType("EXACT");
                    matched.add(offer);
                    continue;
                } else if (isExactMode && offer.getBarcode() != null) {
                    // Mismatched barcode in exact barcode mode
                    continue;
                }
            }

            // 3. Exact Mode Evaluation
            if (isExactMode) {
                // If brand was extracted, check brand compatibility
                if (intent.getExtractedBrand() != null) {
                    String reqBrand = intent.getExtractedBrand().toLowerCase();
                    if (!brandLower.contains(reqBrand) && !nameLower.contains(reqBrand)) {
                        continue;
                    }
                }

                // If variant was extracted, check variant compatibility
                if (intent.getExtractedVariant() != null) {
                    String reqVariant = intent.getExtractedVariant().toLowerCase();
                    if (!nameLower.contains(reqVariant)) {
                        continue;
                    }
                }

                // Match scoring
                BigDecimal reqQty = intent.getExtractedPackSize() != null ? BigDecimal.ONE : null;
                ProductMatchingService.MatchResult result = matchingService.calculateMatch(
                        intent.getNormalizedQuery(),
                        intent.getExtractedBrand(),
                        reqQty,
                        intent.getExtractedUnit(),
                        intent.getPrimaryCategory(),
                        intent.getTargetBarcode(),
                        offer
                );

                if (result.isAcceptableMatch() || result.confidence() >= 0.60) {
                    offer.setMatchConfidence(result.confidence());
                    offer.setMatchType(result.matchType());
                    matched.add(offer);
                }
            } else {
                // 4. Generic Discovery Mode Evaluation
                // In discovery mode, all offers MUST belong to the primary category or allowed subtypes
                if (!isRelevantToCategory(intent, nameLower, brandLower)) {
                    continue;
                }

                double confidence = 0.85;

                // Boost confidence if matches primary category or known allowed types
                if (intent.getAllowedTypes() != null) {
                    for (String subtype : intent.getAllowedTypes()) {
                        if (nameLower.contains(subtype.toLowerCase())) {
                            confidence = 0.95;
                            break;
                        }
                    }
                }

                offer.setMatchConfidence(confidence);
                offer.setMatchType("GENERIC_DISCOVERY");
                matched.add(offer);
            }
        }

        log.info("[ProductMatchingEngine] Filtered {} candidates into {} valid matches for query='{}'",
                candidateOffers.size(), matched.size(), intent.getRawQuery());

        return matched;
    }

    private boolean isRelevantToCategory(ProductSearchIntentDto intent, String nameLower, String brandLower) {
        if (intent.getPrimaryCategory() == null) return true;
        String cat = intent.getPrimaryCategory().toLowerCase();

        if (cat.contains("oil")) {
            return nameLower.contains("oil") || nameLower.contains("ennai") ||
                    (intent.getAllowedTypes() != null && intent.getAllowedTypes().stream().anyMatch(t -> nameLower.contains(t.toLowerCase())));
        } else if (cat.contains("rice")) {
            return nameLower.contains("rice") || nameLower.contains("arisi") || nameLower.contains("basmati") || nameLower.contains("masoori");
        } else if (cat.contains("milk") || cat.contains("dairy")) {
            return nameLower.contains("milk") || nameLower.contains("paal") || nameLower.contains("toned") || nameLower.contains("curd");
        } else if (cat.contains("atta") || cat.contains("flour")) {
            return nameLower.contains("atta") || nameLower.contains("flour") || nameLower.contains("wheat") || nameLower.contains("maida");
        } else if (cat.contains("sugar")) {
            return nameLower.contains("sugar") || nameLower.contains("sakkarai") || nameLower.contains("jaggery");
        } else if (cat.contains("dal")) {
            return nameLower.contains("dal") || nameLower.contains("paruppu") || nameLower.contains("lentil") || nameLower.contains("dhal");
        } else if (cat.contains("detergent") || cat.contains("clean")) {
            return nameLower.contains("detergent") || nameLower.contains("wash") || nameLower.contains("surf") || nameLower.contains("cleaner");
        } else if (cat.contains("personal")) {
            return nameLower.contains("soap") || nameLower.contains("toothpaste") || nameLower.contains("paste") || nameLower.contains("shampoo");
        }
        return true;
    }
}
