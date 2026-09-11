package com.homestock.modules.smartshopping.engine;

import com.homestock.modules.smartshopping.dto.ProductDealDto;
import com.homestock.modules.smartshopping.dto.ProductOfferDto;
import com.homestock.modules.smartshopping.dto.StoreOfferDto;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;
import java.util.stream.Collectors;

/**
 * ProductComparisonEngine:
 * Groups cross-store offers for identical products and calculates price differences and savings.
 * ("Save ₹13 on JioMart vs Amazon")
 */
@Component
@RequiredArgsConstructor
public class ProductComparisonEngine {

    private static final Logger log = LoggerFactory.getLogger(ProductComparisonEngine.class);

    /**
     * Group individual store offers into consolidated multi-store Product Deals.
     */
    public List<ProductDealDto> groupAndCompareDeals(List<ProductOfferDto> offers) {
        if (offers == null || offers.isEmpty()) {
            return Collections.emptyList();
        }

        // Group by canonical product key: brand + normalized title + pack size
        Map<String, List<ProductOfferDto>> groupedOffers = new LinkedHashMap<>();

        for (ProductOfferDto offer : offers) {
            String key = buildProductKey(offer);
            groupedOffers.computeIfAbsent(key, k -> new ArrayList<>()).add(offer);
        }

        List<ProductDealDto> deals = new ArrayList<>();

        for (Map.Entry<String, List<ProductOfferDto>> entry : groupedOffers.entrySet()) {
            List<ProductOfferDto> productOffers = entry.getValue();
            if (productOffers.isEmpty()) continue;

            ProductDealDto deal = buildDealFromGroup(productOffers);
            deals.add(deal);
        }

        log.info("[ProductComparisonEngine] Consolidated {} store offers into {} product deals",
                offers.size(), deals.size());

        return deals;
    }

    private String buildProductKey(ProductOfferDto offer) {
        if (offer.getBarcode() != null && !offer.getBarcode().isBlank()) {
            return "BARCODE:" + offer.getBarcode().trim();
        }
        String brand = offer.getBrand() != null ? offer.getBrand().trim().toLowerCase() : "generic";
        String name = offer.getProductName() != null ? offer.getProductName().trim().toLowerCase() : "";
        String size = offer.getPackageSize() != null ? offer.getPackageSize().trim().toLowerCase() : "";
        return brand + "::" + name.replaceAll("[^a-z0-9]", "") + "::" + size;
    }

    private ProductDealDto buildDealFromGroup(List<ProductOfferDto> offers) {
        // Map to StoreOfferDto
        List<StoreOfferDto> storeOffers = offers.stream()
                .map(o -> StoreOfferDto.builder()
                        .storeName(o.getProvider())
                        .price(o.getEffectivePrice() != null ? o.getEffectivePrice() : o.getPrice())
                        .mrp(o.getPrice())
                        .deliveryFee(o.getDeliveryCharge())
                        .estimatedDelivery(o.getEstimatedDelivery())
                        .availability(o.getAvailability())
                        .productUrl(o.getProductUrl())
                        .affiliateUrl(o.getAffiliateUrl())
                        .deepLink(o.getDeepLink())
                        .rating(o.getRating() != null ? o.getRating().doubleValue() : null)
                        .reviewCount(o.getReviewCount())
                        .build())
                .sorted(Comparator.comparing(StoreOfferDto::getPrice, Comparator.nullsLast(BigDecimal::compareTo)))
                .collect(Collectors.toList());

        // Representative offer
        ProductOfferDto bestOffer = offers.stream()
                .min(Comparator.comparing((ProductOfferDto o) -> o.getEffectivePrice() != null ? o.getEffectivePrice() : o.getPrice(), Comparator.nullsLast(BigDecimal::compareTo)))
                .orElse(offers.get(0));

        BigDecimal minPrice = storeOffers.get(0).getPrice();
        BigDecimal maxPrice = storeOffers.get(storeOffers.size() - 1).getPrice();
        BigDecimal savings = maxPrice.subtract(minPrice);
        String comparisonStore = storeOffers.size() > 1 ? storeOffers.get(storeOffers.size() - 1).getStoreName() : null;

        Double discountPercent = null;
        if (maxPrice.compareTo(BigDecimal.ZERO) > 0 && savings.compareTo(BigDecimal.ZERO) > 0) {
            discountPercent = savings.divide(maxPrice, 4, RoundingMode.HALF_UP)
                    .multiply(new BigDecimal("100"))
                    .setScale(1, RoundingMode.HALF_UP)
                    .doubleValue();
        }

        // Generate synthetic ID
        String dealId = "DEAL-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        return ProductDealDto.builder()
                .id(dealId)
                .productName(bestOffer.getProductName())
                .brand(bestOffer.getBrand())
                .packageSize(bestOffer.getPackageSize())
                .unit(bestOffer.getUnit())
                .bestPrice(minPrice)
                .mrp(maxPrice)
                .discountPercent(discountPercent)
                .bestProvider(storeOffers.get(0).getStoreName())
                .savingsVsHighest(savings)
                .comparisonStore(comparisonStore)
                .imageUrl(bestOffer.getImageUrl())
                .productUrl(bestOffer.getAffiliateUrl() != null ? bestOffer.getAffiliateUrl() : bestOffer.getProductUrl())
                .deepLink(bestOffer.getDeepLink())
                .rating(bestOffer.getRating() != null ? bestOffer.getRating().doubleValue() : 4.2)
                .reviewCount(bestOffer.getReviewCount() != null ? bestOffer.getReviewCount() : 1200)
                .matchConfidence(bestOffer.getMatchConfidence())
                .storeOffers(storeOffers)
                .build();
    }
}
