package com.homestock.modules.smartshopping.engine;

import com.homestock.modules.smartshopping.dto.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.List;

/**
 * AIRecommendationEngine:
 * Generates neutral, factual AI summaries and highlights without assuming user preferences.
 */
@Component
public class AIRecommendationEngine {

    private static final Logger log = LoggerFactory.getLogger(AIRecommendationEngine.class);

    public AIRecommendationResult generateSummaryAndHighlights(
            ProductSearchIntentDto intent,
            List<ProductDealDto> deals,
            ProductDealDto lowestPriceDeal,
            ProductDealDto bestValueDeal,
            ProductDealDto popularDeal
    ) {
        if (deals == null || deals.isEmpty()) {
            DealSummaryDto emptySummary = DealSummaryDto.builder()
                    .totalProducts(0)
                    .aiRecommendation("No active deals found matching your search. Try a broader category name.")
                    .build();
            return new AIRecommendationResult(emptySummary, new DealHighlightsDto());
        }

        BigDecimal minPrice = deals.stream()
                .map(ProductDealDto::getBestPrice)
                .filter(p -> p != null)
                .min(BigDecimal::compareTo)
                .orElse(BigDecimal.ZERO);

        BigDecimal maxPrice = deals.stream()
                .map(ProductDealDto::getBestPrice)
                .filter(p -> p != null)
                .max(BigDecimal::compareTo)
                .orElse(BigDecimal.ZERO);

        String aiText = buildFactualSummary(intent, deals, lowestPriceDeal, bestValueDeal, popularDeal);

        DealSummaryDto summary = DealSummaryDto.builder()
                .totalProducts(deals.size())
                .priceRangeMin(minPrice)
                .priceRangeMax(maxPrice)
                .lowestPrice(lowestPriceDeal != null ? lowestPriceDeal.getBestPrice() : minPrice)
                .bestUnitValue(bestValueDeal != null ? bestValueDeal.getUnitPrice() : null)
                .bestUnitValueLabel(bestValueDeal != null ? bestValueDeal.getUnitPriceLabel() : null)
                .aiRecommendation(aiText)
                .build();

        DealHighlightsDto highlights = DealHighlightsDto.builder()
                .lowestPrice(lowestPriceDeal)
                .bestValue(bestValueDeal)
                .popular(popularDeal)
                .build();

        return new AIRecommendationResult(summary, highlights);
    }

    private String buildFactualSummary(
            ProductSearchIntentDto intent,
            List<ProductDealDto> deals,
            ProductDealDto lowest,
            ProductDealDto bestValue,
            ProductDealDto popular
    ) {
        StringBuilder sb = new StringBuilder();

        if ("EXACT_PRODUCT".equalsIgnoreCase(intent.getSearchMode())) {
            ProductDealDto top = deals.get(0);
            sb.append("Found ").append(top.getProductName());
            if (top.getPackageSize() != null) {
                sb.append(" (").append(top.getPackageSize()).append(")");
            }
            if (top.getStoreOffers() != null && !top.getStoreOffers().isEmpty()) {
                sb.append(" across ").append(top.getStoreOffers().size()).append(" stores. ");
                sb.append(top.getBestProvider()).append(" currently offers the lowest price at ₹").append(top.getBestPrice());
                if (top.getSavingsVsHighest() != null && top.getSavingsVsHighest().compareTo(BigDecimal.ZERO) > 0 && top.getComparisonStore() != null) {
                    sb.append(" (saves ₹").append(top.getSavingsVsHighest()).append(" vs ").append(top.getComparisonStore()).append(").");
                } else {
                    sb.append(".");
                }
            } else {
                sb.append(" at ₹").append(top.getBestPrice()).append(".");
            }
        } else {
            // Generic discovery
            sb.append("Showing ").append(deals.size()).append(" options for ")
                    .append(intent.getPrimaryCategory() != null ? intent.getPrimaryCategory().toLowerCase() : intent.getRawQuery())
                    .append(". ");

            if (bestValue != null && bestValue.getUnitPriceLabel() != null) {
                sb.append("For best value, ").append(bestValue.getProductName())
                        .append(" (").append(bestValue.getPackageSize() != null ? bestValue.getPackageSize() : "")
                        .append(") is cheapest per unit at ").append(bestValue.getUnitPriceLabel()).append(". ");
            }

            if (lowest != null && (bestValue == null || !lowest.getId().equals(bestValue.getId()))) {
                sb.append("Lowest entry price is ₹").append(lowest.getBestPrice())
                        .append(" for ").append(lowest.getProductName())
                        .append(" on ").append(lowest.getBestProvider()).append(".");
            }
        }

        return sb.toString().trim();
    }

    public record AIRecommendationResult(
            DealSummaryDto summary,
            DealHighlightsDto highlights
    ) {}
}
