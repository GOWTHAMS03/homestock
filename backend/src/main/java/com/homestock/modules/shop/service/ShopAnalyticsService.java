package com.homestock.modules.shop.service;

import com.homestock.modules.deals.entity.NearbyShop;
import com.homestock.modules.deals.entity.ShopProductOffer;
import com.homestock.modules.deals.repository.NearbyShopRepository;
import com.homestock.modules.deals.repository.ShopProductOfferRepository;
import com.homestock.modules.shop.dto.ShopDashboardResponse;
import com.homestock.modules.shop.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Shop Owner analytics and dashboard service.
 * All customer data is aggregated and anonymized.
 */
@Service
@RequiredArgsConstructor
public class ShopAnalyticsService {

    private final NearbyShopRepository nearbyShopRepository;
    private final ShopProductOfferRepository shopProductOfferRepository;
    private final ShopProductViewRepository shopProductViewRepository;
    private final ShopSearchEventRepository shopSearchEventRepository;
    private final ShopDealRepository shopDealRepository;
    private final ShopSubscriptionRepository subscriptionRepository;
    private final SubscriptionPlanRepository planRepository;

    /**
     * Build shop owner dashboard with views, demand, and attention items.
     */
    public ShopDashboardResponse getDashboard(UUID shopId) {
        NearbyShop shop = nearbyShopRepository.findById(shopId)
                .orElseThrow(() -> new com.homestock.core.exception.ResourceNotFoundException("Shop not found"));

        Instant todayStart = Instant.now().truncatedTo(ChronoUnit.DAYS);
        Instant weekAgo = Instant.now().minus(7, ChronoUnit.DAYS);

        // Today's views
        long todayViews = shopProductViewRepository.countByShopIdAndViewedAtAfter(shopId, todayStart);

        // Product views (top viewed)
        List<Object[]> topViewed = shopProductViewRepository.findTopViewedProducts(shopId, weekAgo);
        List<ShopDashboardResponse.PopularProduct> popularProducts = topViewed.stream()
                .limit(5)
                .map(row -> {
                    UUID productId = (UUID) row[0];
                    long count = ((Number) row[1]).longValue();
                    ShopProductOffer offer = shopProductOfferRepository.findById(productId).orElse(null);
                    return ShopDashboardResponse.PopularProduct.builder()
                            .productName(offer != null ? offer.getRawProductName() : "Unknown")
                            .viewCount(count)
                            .build();
                })
                .toList();

        // Active deals count
        long activeDeals = shopDealRepository.countActiveDeals(shopId, Instant.now());

        // Nearby demand (what customers are searching for near this shop)
        List<ShopDashboardResponse.DemandItem> nearbyDemand = getNearbyDemand(shop);

        // Products needing attention
        List<ShopDashboardResponse.AttentionItem> attentionItems = getAttentionItems(shopId);

        // Subscription info
        String subscriptionPlan = "FREE";
        int maxProducts = 50;
        subscriptionRepository.findActiveSubscription(shopId).ifPresent(sub -> {
            // Note: can't mutate local vars, so we use the builder pattern below
        });

        var subOpt = subscriptionRepository.findActiveSubscription(shopId);
        if (subOpt.isPresent()) {
            subscriptionPlan = subOpt.get().getPlan().getName();
            maxProducts = subOpt.get().getPlan().getMaxProducts();
        }

        return ShopDashboardResponse.builder()
                .todayViews(todayViews)
                .productViews(topViewed.stream().mapToLong(r -> ((Number) r[1]).longValue()).sum())
                .activeDeals(activeDeals)
                .totalProducts(shop.getProductCount())
                .subscriptionPlan(subscriptionPlan)
                .maxProducts(maxProducts)
                .popularProducts(popularProducts)
                .nearbyDemand(nearbyDemand)
                .productsNeedingAttention(attentionItems)
                .build();
    }

    private List<ShopDashboardResponse.DemandItem> getNearbyDemand(NearbyShop shop) {
        try {
            double radiusKm = 5.0;
            double latDelta = radiusKm / 111.0;
            double lonDelta = radiusKm / (111.0 * Math.cos(Math.toRadians(shop.getLatitude().doubleValue())));

            Instant weekAgo = Instant.now().minus(7, ChronoUnit.DAYS);

            List<Object[]> topSearches = shopSearchEventRepository.findTopSearchesNearLocation(
                    weekAgo,
                    shop.getLatitude().subtract(BigDecimal.valueOf(latDelta)),
                    shop.getLatitude().add(BigDecimal.valueOf(latDelta)),
                    shop.getLongitude().subtract(BigDecimal.valueOf(lonDelta)),
                    shop.getLongitude().add(BigDecimal.valueOf(lonDelta))
            );

            return topSearches.stream()
                    .limit(10)
                    .map(row -> {
                        String query = (String) row[0];
                        long count = ((Number) row[1]).longValue();
                        String level = count > 50 ? "HIGH" : count > 20 ? "MEDIUM" : "LOW";
                        return ShopDashboardResponse.DemandItem.builder()
                                .query(query)
                                .searchCount(count)
                                .demandLevel(level)
                                .build();
                    })
                    .toList();
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    private List<ShopDashboardResponse.AttentionItem> getAttentionItems(UUID shopId) {
        List<ShopDashboardResponse.AttentionItem> items = new ArrayList<>();

        // Out of stock products
        List<ShopProductOffer> outOfStock = shopProductOfferRepository.findByShopIdAndAvailabilityStatus(shopId, "OUT_OF_STOCK");
        outOfStock.stream().limit(5).forEach(offer ->
                items.add(ShopDashboardResponse.AttentionItem.builder()
                        .productName(offer.getRawProductName())
                        .reason("OUT_OF_STOCK")
                        .productId(offer.getId().toString())
                        .build())
        );

        // Products not updated in 7+ days
        Instant weekAgo = Instant.now().minus(7, ChronoUnit.DAYS);
        List<ShopProductOffer> staleProducts = shopProductOfferRepository.findByShopIdOrderByRawProductNameAsc(shopId).stream()
                .filter(o -> o.getLastVerifiedAt() != null && o.getLastVerifiedAt().isBefore(weekAgo))
                .limit(5)
                .toList();
        staleProducts.forEach(offer ->
                items.add(ShopDashboardResponse.AttentionItem.builder()
                        .productName(offer.getRawProductName())
                        .reason("PRICE_NOT_UPDATED")
                        .productId(offer.getId().toString())
                        .build())
        );

        return items;
    }
}
