package com.homestock.modules.smartshopping.engine;

import com.homestock.modules.smartshopping.dto.*;
import com.homestock.modules.smartshopping.service.UnitNormalizationService;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

/**
 * DealRankingEngine:
 * Calculates unit prices (₹/L, ₹/kg), assigns highlight badges (Lowest Price, Best Value, Popular),
 * extracts dynamic filter options, and sorts deals based on user preference.
 */
@Component
@RequiredArgsConstructor
public class DealRankingEngine {

    private static final Logger log = LoggerFactory.getLogger(DealRankingEngine.class);

    private final UnitNormalizationService unitService;

    public RankedDealsResult rankAndFilter(List<ProductDealDto> rawDeals, ProductSearchIntentDto intent, String sortBy) {
        if (rawDeals == null || rawDeals.isEmpty()) {
            return new RankedDealsResult(
                    Collections.emptyList(),
                    null, null, null,
                    DealFiltersDto.builder()
                            .availableTypes(Collections.emptyList())
                            .availableBrands(Collections.emptyList())
                            .availablePackSizes(Collections.emptyList())
                            .availableStores(Collections.emptyList())
                            .build()
            );
        }

        // 1. Calculate Unit Prices & Variant Types
        for (ProductDealDto deal : rawDeals) {
            deal.setCategory(intent.getPrimaryCategory());
            assignVariantType(deal);
            calculateUnitPrice(deal);
        }

        // 2. Identify Highlights (Lowest Price, Best Value, Popular)
        ProductDealDto lowestPriceDeal = null;
        ProductDealDto bestValueDeal = null;
        ProductDealDto popularDeal = null;

        BigDecimal minAbsolutePrice = null;
        BigDecimal minUnitPrice = null;
        double maxPopularityScore = -1.0;

        for (ProductDealDto deal : rawDeals) {
            // Lowest Price check
            if (deal.getBestPrice() != null) {
                if (minAbsolutePrice == null || deal.getBestPrice().compareTo(minAbsolutePrice) < 0) {
                    minAbsolutePrice = deal.getBestPrice();
                    lowestPriceDeal = deal;
                }
            }

            // Best Value check
            if (deal.getUnitPrice() != null) {
                if (minUnitPrice == null || deal.getUnitPrice().compareTo(minUnitPrice) < 0) {
                    minUnitPrice = deal.getUnitPrice();
                    bestValueDeal = deal;
                }
            }

            // Popularity score: rating * log(reviewCount)
            double rating = deal.getRating() != null ? deal.getRating() : 4.0;
            int reviews = deal.getReviewCount() != null ? deal.getReviewCount() : 100;
            double popScore = rating * Math.log10(Math.max(10, reviews));
            if (popScore > maxPopularityScore) {
                maxPopularityScore = popScore;
                popularDeal = deal;
            }
        }

        // Tag deals with highlight flags
        if (lowestPriceDeal != null) lowestPriceDeal.setLowestPrice(true);
        if (bestValueDeal != null) bestValueDeal.setBestValue(true);
        if (popularDeal != null) popularDeal.setPopular(true);

        // 3. Extract Dynamic Filters
        DealFiltersDto filters = extractFilters(rawDeals);

        // 4. Sort Deals
        List<ProductDealDto> sortedDeals = new ArrayList<>(rawDeals);
        sortDeals(sortedDeals, sortBy, intent);

        return new RankedDealsResult(
                sortedDeals,
                lowestPriceDeal,
                bestValueDeal,
                popularDeal,
                filters
        );
    }

    private void assignVariantType(ProductDealDto deal) {
        String name = deal.getProductName() != null ? deal.getProductName().toLowerCase() : "";

        // Cooking Oil variants
        if (name.contains("sunflower")) deal.setVariantType("Sunflower");
        else if (name.contains("groundnut") || name.contains("peanut")) deal.setVariantType("Groundnut");
        else if (name.contains("rice bran") || name.contains("ricebran")) deal.setVariantType("Rice Bran");
        else if (name.contains("coconut")) deal.setVariantType("Coconut");
        else if (name.contains("sesame") || name.contains("gingelly")) deal.setVariantType("Sesame");
        else if (name.contains("mustard")) deal.setVariantType("Mustard");
        else if (name.contains("olive")) deal.setVariantType("Olive");

        // Rice variants
        else if (name.contains("basmati")) deal.setVariantType("Basmati");
        else if (name.contains("sona masoori")) deal.setVariantType("Sona Masoori");
        else if (name.contains("ponni")) deal.setVariantType("Ponni");
        else if (name.contains("idli") || name.contains("idly")) deal.setVariantType("Idli Rice");

        // Milk variants
        else if (name.contains("toned") && !name.contains("double")) deal.setVariantType("Toned");
        else if (name.contains("full cream")) deal.setVariantType("Full Cream");
        else if (name.contains("cow milk")) deal.setVariantType("Cow Milk");

        // Atta variants
        else if (name.contains("whole wheat") || name.contains("sharbati")) deal.setVariantType("Whole Wheat");
        else if (name.contains("multigrain")) deal.setVariantType("Multigrain");

        // Default
        else deal.setVariantType(deal.getBrand() != null ? deal.getBrand() : "Standard");
    }

    private void calculateUnitPrice(ProductDealDto deal) {
        if (deal.getBestPrice() == null) return;

        BigDecimal qty = null;
        String unit = deal.getUnit();

        if (deal.getPackageSize() != null) {
            UnitNormalizationService.PackageSize parsed = unitService.parsePackageSize(deal.getPackageSize());
            if (parsed != null) {
                qty = parsed.quantity();
                unit = parsed.unit();
            }
        }

        if (qty == null) {
            qty = BigDecimal.ONE;
        }

        UnitNormalizationService.PricePerUnit ppu = unitService.calculatePricePerUnit(deal.getBestPrice(), qty, unit);
        if (ppu != null) {
            deal.setUnitPrice(ppu.price());
            deal.setUnitPriceLabel(ppu.label());
        } else {
            deal.setUnitPrice(deal.getBestPrice());
            deal.setUnitPriceLabel("₹" + deal.getBestPrice() + "/" + (unit != null ? unit : "pack"));
        }
    }

    private DealFiltersDto extractFilters(List<ProductDealDto> deals) {
        Map<String, Integer> typeCounts = new LinkedHashMap<>();
        Map<String, Integer> brandCounts = new LinkedHashMap<>();
        Map<String, Integer> sizeCounts = new LinkedHashMap<>();
        Map<String, Integer> storeCounts = new LinkedHashMap<>();

        for (ProductDealDto d : deals) {
            if (d.getVariantType() != null) {
                typeCounts.merge(d.getVariantType(), 1, Integer::sum);
            }
            if (d.getBrand() != null) {
                brandCounts.merge(d.getBrand(), 1, Integer::sum);
            }
            if (d.getPackageSize() != null) {
                sizeCounts.merge(d.getPackageSize(), 1, Integer::sum);
            }
            if (d.getStoreOffers() != null) {
                for (StoreOfferDto s : d.getStoreOffers()) {
                    storeCounts.merge(s.getStoreName(), 1, Integer::sum);
                }
            }
        }

        return DealFiltersDto.builder()
                .availableTypes(toFilterList(typeCounts))
                .availableBrands(toFilterList(brandCounts))
                .availablePackSizes(toFilterList(sizeCounts))
                .availableStores(toFilterList(storeCounts))
                .build();
    }

    private List<FilterOptionDto> toFilterList(Map<String, Integer> counts) {
        return counts.entrySet().stream()
                .map(e -> FilterOptionDto.builder().key(e.getKey()).label(e.getKey()).count(e.getValue()).build())
                .sorted((a, b) -> Integer.compare(b.getCount(), a.getCount()))
                .collect(Collectors.toList());
    }

    private void sortDeals(List<ProductDealDto> deals, String sortBy, ProductSearchIntentDto intent) {
        String sort = sortBy != null ? sortBy.toLowerCase().trim() : "default";

        switch (sort) {
            case "lowest_price":
            case "price_asc":
                deals.sort(Comparator.comparing(d -> d.getBestPrice() != null ? d.getBestPrice() : BigDecimal.valueOf(999999)));
                break;
            case "best_value":
            case "value_asc":
                deals.sort(Comparator.comparing(d -> d.getUnitPrice() != null ? d.getUnitPrice() : BigDecimal.valueOf(999999)));
                break;
            case "highest_saving":
                deals.sort((a, b) -> {
                    BigDecimal s1 = a.getSavingsVsHighest() != null ? a.getSavingsVsHighest() : BigDecimal.ZERO;
                    BigDecimal s2 = b.getSavingsVsHighest() != null ? b.getSavingsVsHighest() : BigDecimal.ZERO;
                    return s2.compareTo(s1);
                });
                break;
            case "rating":
                deals.sort((a, b) -> Double.compare(b.getRating() != null ? b.getRating() : 0.0, a.getRating() != null ? a.getRating() : 0.0));
                break;
            default:
                // Default: Best Value / Highlighted deals float to the top
                deals.sort((a, b) -> {
                    int scoreA = (a.isBestValue() ? 3 : 0) + (a.isLowestPrice() ? 2 : 0) + (a.isPopular() ? 1 : 0);
                    int scoreB = (b.isBestValue() ? 3 : 0) + (b.isLowestPrice() ? 2 : 0) + (b.isPopular() ? 1 : 0);
                    if (scoreA != scoreB) {
                        return Integer.compare(scoreB, scoreA);
                    }
                    BigDecimal p1 = a.getBestPrice() != null ? a.getBestPrice() : BigDecimal.valueOf(999999);
                    BigDecimal p2 = b.getBestPrice() != null ? b.getBestPrice() : BigDecimal.valueOf(999999);
                    return p1.compareTo(p2);
                });
                break;
        }
    }

    public record RankedDealsResult(
            List<ProductDealDto> deals,
            ProductDealDto lowestPriceDeal,
            ProductDealDto bestValueDeal,
            ProductDealDto popularDeal,
            DealFiltersDto filters
    ) {}
}
