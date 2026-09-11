package com.homestock.modules.smartshopping.service.ranking;

import com.homestock.modules.smartshopping.dto.*;
import com.homestock.modules.smartshopping.service.UnitNormalizationService;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Deal Ranking Service:
 * Calculates effective prices (price + delivery fee), unit prices, required quantity costs,
 * dynamic filter facets, and weighted Deal Scores.
 * Strictly separates Exact Deals from Similar Products (Brand Protection).
 */
@Service
@RequiredArgsConstructor
public class DealRankingService {

    private static final Logger log = LoggerFactory.getLogger(DealRankingService.class);

    private final UnitNormalizationService unitService;

    // Configurable Deal Score weights
    @Value("${app.smart-shopping.ranking.weight.match:0.40}")
    private double weightMatch = 0.40;

    @Value("${app.smart-shopping.ranking.weight.price:0.25}")
    private double weightPrice = 0.25;

    @Value("${app.smart-shopping.ranking.weight.seller:0.10}")
    private double weightSeller = 0.10;

    @Value("${app.smart-shopping.ranking.weight.availability:0.10}")
    private double weightAvailability = 0.10;

    @Value("${app.smart-shopping.ranking.weight.discount:0.05}")
    private double weightDiscount = 0.05;

    @Value("${app.smart-shopping.ranking.weight.freshness:0.10}")
    private double weightFreshness = 0.10;

    public RankedDealsContainer rankAndSegregate(
            List<ProductDealDto> deals,
            ProductIntent intent,
            String sortBy
    ) {
        if (deals == null || deals.isEmpty()) {
            return new RankedDealsContainer(
                    Collections.emptyList(),
                    Collections.emptyList(),
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

        BigDecimal reqQuantity = intent.getQuantity() != null ? intent.getQuantity() : BigDecimal.ONE;

        // 1. Calculate Unit Price, Effective Price, and Required Quantity Cost
        for (ProductDealDto deal : deals) {
            assignVariantType(deal);
            calculateEffectiveAndUnitPrices(deal, reqQuantity);
        }

        // Find min effective price across deals for relative price scoring
        BigDecimal minEffectivePrice = deals.stream()
                .map(ProductDealDto::getEffectivePrice)
                .filter(Objects::nonNull)
                .min(BigDecimal::compareTo)
                .orElse(BigDecimal.valueOf(100));

        // 2. Compute Deal Score for each deal
        for (ProductDealDto deal : deals) {
            double dealScore = calculateDealScore(deal, minEffectivePrice);
            deal.setDealScore(dealScore);
        }

        // 3. Segregate into Exact Deals vs Similar Deals (Brand Protection Rule)
        List<ProductDealDto> exactDeals = new ArrayList<>();
        List<ProductDealDto> similarDeals = new ArrayList<>();

        boolean isExactMode = intent.getSearchIntent() == SearchIntent.EXACT_PRODUCT ||
                              intent.getSearchIntent() == SearchIntent.BRANDED_PRODUCT;

        String reqBrand = intent.getBrand() != null ? intent.getBrand().trim().toLowerCase() : null;

        for (ProductDealDto deal : deals) {
            String dealBrand = deal.getBrand() != null ? deal.getBrand().trim().toLowerCase() : null;
            boolean brandMatched = reqBrand == null || (dealBrand != null && dealBrand.contains(reqBrand));

            double matchScore = deal.getMatchScore() != null ? deal.getMatchScore() : 70.0;
            boolean isHighMatch = matchScore >= 85.0;

            if (isExactMode) {
                if (brandMatched && isHighMatch) {
                    deal.setExactMatch(true);
                    exactDeals.add(deal);
                } else {
                    deal.setExactMatch(false);
                    similarDeals.add(deal);
                }
            } else {
                // In generic discovery mode, all qualifying category deals are eligible
                deal.setExactMatch(isHighMatch);
                exactDeals.add(deal);
            }
        }

        // 4. Sort each collection
        sortDeals(exactDeals, sortBy, isExactMode);
        sortDeals(similarDeals, sortBy, false);

        // Primary display deals
        List<ProductDealDto> primaryDeals = !exactDeals.isEmpty() ? exactDeals : similarDeals;

        // 5. Determine Highlights (Lowest Price, Best Value, Popular)
        ProductDealDto lowestPriceDeal = null;
        ProductDealDto bestValueDeal = null;
        ProductDealDto popularDeal = null;

        BigDecimal minPrice = null;
        BigDecimal minUnitPrice = null;
        double maxPopScore = -1.0;

        for (ProductDealDto d : primaryDeals) {
            BigDecimal effPrice = d.getEffectivePrice() != null ? d.getEffectivePrice() : d.getBestPrice();
            if (effPrice != null && (minPrice == null || effPrice.compareTo(minPrice) < 0)) {
                minPrice = effPrice;
                lowestPriceDeal = d;
            }

            if (d.getUnitPrice() != null && (minUnitPrice == null || d.getUnitPrice().compareTo(minUnitPrice) < 0)) {
                minUnitPrice = d.getUnitPrice();
                bestValueDeal = d;
            }

            double rating = d.getRating() != null ? d.getRating() : 4.0;
            int reviews = d.getReviewCount() != null ? d.getReviewCount() : 100;
            double popScore = rating * Math.log10(Math.max(10, reviews));
            if (popScore > maxPopScore) {
                maxPopScore = popScore;
                popularDeal = d;
            }
        }

        if (lowestPriceDeal != null) lowestPriceDeal.setLowestPrice(true);
        if (bestValueDeal != null) bestValueDeal.setBestValue(true);
        if (popularDeal != null) popularDeal.setPopular(true);

        // 6. Extract Dynamic Filter Facets
        DealFiltersDto filters = extractFilters(deals);

        return new RankedDealsContainer(
                primaryDeals,
                exactDeals,
                similarDeals,
                lowestPriceDeal,
                bestValueDeal,
                popularDeal,
                filters
        );
    }

    private void calculateEffectiveAndUnitPrices(ProductDealDto deal, BigDecimal reqQuantity) {
        BigDecimal basePrice = deal.getBestPrice() != null ? deal.getBestPrice() : BigDecimal.ZERO;
        BigDecimal delivery = deal.getDeliveryCharge() != null ? deal.getDeliveryCharge() : BigDecimal.ZERO;
        BigDecimal effectivePrice = basePrice.add(delivery);
        deal.setEffectivePrice(effectivePrice);

        // Unit Price calculation
        BigDecimal packQty = BigDecimal.ONE;
        String packUnit = deal.getUnit();

        String packSize = deal.getPackageSize() != null ? deal.getPackageSize() : deal.getPackSize();
        if (packSize != null) {
            UnitNormalizationService.PackageSize parsed = unitService.parsePackageSize(packSize);
            if (parsed != null) {
                packQty = parsed.quantity();
                packUnit = parsed.unit();
            }
        }

        UnitNormalizationService.PricePerUnit ppu = unitService.calculatePricePerUnit(effectivePrice, packQty, packUnit);
        if (ppu != null) {
            deal.setUnitPrice(ppu.price());
            deal.setPricePerUnit(ppu.price());
            deal.setUnitPriceLabel(ppu.label());
        } else {
            deal.setUnitPrice(effectivePrice);
            deal.setPricePerUnit(effectivePrice);
            deal.setUnitPriceLabel("₹" + effectivePrice + "/" + (packUnit != null ? packUnit : "pack"));
        }

        // Required total quantity cost = effectivePrice * reqQuantity
        deal.setRequiredQuantityCost(effectivePrice.multiply(reqQuantity).setScale(2, RoundingMode.HALF_UP));
    }

    private void assignVariantType(ProductDealDto deal) {
        if (deal.getVariantType() != null && !deal.getVariantType().isBlank()) return;
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

    private double calculateDealScore(ProductDealDto deal, BigDecimal minEffectivePrice) {
        // 1. Product Match component (0-100)
        double match = deal.getMatchScore() != null ? deal.getMatchScore() : 70.0;

        // 2. Price competitiveness component (0-100)
        double priceScore = 50.0;
        BigDecimal eff = deal.getEffectivePrice();
        if (eff != null && eff.compareTo(BigDecimal.ZERO) > 0 && minEffectivePrice.compareTo(BigDecimal.ZERO) > 0) {
            double ratio = minEffectivePrice.doubleValue() / eff.doubleValue();
            priceScore = Math.min(100.0, ratio * 100.0);
        }

        // 3. Seller reliability (0-100)
        double sellerScore = 80.0;
        if (deal.getBestProvider() != null) {
            String p = deal.getBestProvider().toUpperCase();
            if (p.contains("BIGBASKET") || p.contains("BLINKIT") || p.contains("JIOMART") || p.contains("AMAZON")) {
                sellerScore = 95.0;
            }
        }

        // 4. Availability component
        double availScore = "IN_STOCK".equalsIgnoreCase(deal.getAvailability()) ? 100.0 : 40.0;

        // 5. Discount component (0-100)
        double discountScore = deal.getDiscountPercent() != null ? Math.min(100.0, deal.getDiscountPercent() * 2) : 20.0;

        // 6. Freshness component (0-100)
        double freshnessScore = 80.0;
        if (deal.getLastVerifiedAt() != null) {
            long hours = Duration.between(deal.getLastVerifiedAt(), Instant.now()).toHours();
            if (hours <= 2) freshnessScore = 100.0;
            else if (hours <= 12) freshnessScore = 90.0;
            else if (hours <= 24) freshnessScore = 75.0;
            else freshnessScore = 50.0;
        }

        return (match * weightMatch) +
                (priceScore * weightPrice) +
                (sellerScore * weightSeller) +
                (availScore * weightAvailability) +
                (discountScore * weightDiscount) +
                (freshnessScore * weightFreshness);
    }

    private void sortDeals(List<ProductDealDto> list, String sortBy, boolean isExactMode) {
        String sort = sortBy != null ? sortBy.toLowerCase().trim() : "default";

        switch (sort) {
            case "lowest_price":
            case "price_asc":
                list.sort(Comparator.comparing(d -> d.getEffectivePrice() != null ? d.getEffectivePrice() : BigDecimal.valueOf(999999)));
                break;
            case "best_value":
            case "value_asc":
                list.sort(Comparator.comparing(d -> d.getUnitPrice() != null ? d.getUnitPrice() : BigDecimal.valueOf(999999)));
                break;
            case "rating":
                list.sort((a, b) -> Double.compare(b.getRating() != null ? b.getRating() : 0.0, a.getRating() != null ? a.getRating() : 0.0));
                break;
            default:
                // Default: Ranked by DealScore
                list.sort((a, b) -> {
                    if (isExactMode) {
                        // For exact products: High Match Score has strict precedence over cheaper price
                        double mDiff = (b.getMatchScore() != null ? b.getMatchScore() : 0.0) - (a.getMatchScore() != null ? a.getMatchScore() : 0.0);
                        if (Math.abs(mDiff) >= 10.0) {
                            return Double.compare(b.getMatchScore(), a.getMatchScore());
                        }
                    }
                    double sA = a.getDealScore() != null ? a.getDealScore() : 0.0;
                    double sB = b.getDealScore() != null ? b.getDealScore() : 0.0;
                    return Double.compare(sB, sA);
                });
                break;
        }
    }

    private DealFiltersDto extractFilters(List<ProductDealDto> deals) {
        Map<String, Integer> typeCounts = new LinkedHashMap<>();
        Map<String, Integer> brandCounts = new LinkedHashMap<>();
        Map<String, Integer> sizeCounts = new LinkedHashMap<>();
        Map<String, Integer> storeCounts = new LinkedHashMap<>();

        for (ProductDealDto d : deals) {
            if (d.getVariantType() != null) typeCounts.merge(d.getVariantType(), 1, Integer::sum);
            if (d.getBrand() != null) brandCounts.merge(d.getBrand(), 1, Integer::sum);
            String size = d.getPackageSize() != null ? d.getPackageSize() : d.getPackSize();
            if (size != null) sizeCounts.merge(size, 1, Integer::sum);
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

    public record RankedDealsContainer(
            List<ProductDealDto> primaryDeals,
            List<ProductDealDto> exactDeals,
            List<ProductDealDto> similarDeals,
            ProductDealDto lowestPriceDeal,
            ProductDealDto bestValueDeal,
            ProductDealDto popularDeal,
            DealFiltersDto filters
    ) {}
}
