package com.homestock.modules.shop.service;

import com.homestock.modules.deals.entity.NearbyShop;
import com.homestock.modules.deals.entity.ShopProductOffer;
import com.homestock.modules.deals.repository.NearbyShopRepository;
import com.homestock.modules.deals.repository.ShopProductOfferRepository;
import com.homestock.modules.shop.dto.ShopDealResponse;
import com.homestock.modules.shop.dto.ShopProductResponse;
import com.homestock.modules.shop.dto.ShopProfileResponse;
import com.homestock.modules.shop.entity.ShopDeal;
import com.homestock.modules.shop.entity.ShopProductView;
import com.homestock.modules.shop.entity.ShopSearchEvent;
import com.homestock.modules.shop.repository.ShopDealRepository;
import com.homestock.modules.shop.repository.ShopProductViewRepository;
import com.homestock.modules.shop.repository.ShopSearchEventRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.MathContext;
import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Customer-facing shop and product discovery service.
 * Only returns VERIFIED shops; uses bounding-box geospatial querying for performance.
 */
@Service
@RequiredArgsConstructor
public class ShopDiscoveryService {

    private static final Logger log = LoggerFactory.getLogger(ShopDiscoveryService.class);
    private static final double EARTH_RADIUS_KM = 6371.0;

    private final NearbyShopRepository nearbyShopRepository;
    private final ShopProductOfferRepository shopProductOfferRepository;
    private final ShopDealRepository shopDealRepository;
    private final ShopProductViewRepository shopProductViewRepository;
    private final ShopSearchEventRepository shopSearchEventRepository;

    /**
     * Find verified shops near a given location.
     */
    public List<ShopProfileResponse> findNearbyVerifiedShops(BigDecimal lat, BigDecimal lon, double radiusKm) {
        if (lat == null || lon == null) return Collections.emptyList();

        // Calculate bounding box for efficient DB query
        double latDelta = radiusKm / 111.0;
        double lonDelta = radiusKm / (111.0 * Math.cos(Math.toRadians(lat.doubleValue())));

        BigDecimal minLat = lat.subtract(BigDecimal.valueOf(latDelta));
        BigDecimal maxLat = lat.add(BigDecimal.valueOf(latDelta));
        BigDecimal minLon = lon.subtract(BigDecimal.valueOf(lonDelta));
        BigDecimal maxLon = lon.add(BigDecimal.valueOf(lonDelta));

        List<NearbyShop> shops = nearbyShopRepository.findVerifiedShopsInBoundingBox(minLat, maxLat, minLon, maxLon);

        return shops.stream()
                .map(shop -> {
                    ShopProfileResponse response = ShopProfileResponse.fromEntity(shop);
                    double distance = calculateDistance(lat.doubleValue(), lon.doubleValue(),
                            shop.getLatitude().doubleValue(), shop.getLongitude().doubleValue());
                    response.setDistanceKm(Math.round(distance * 10.0) / 10.0);
                    response.setActiveDealCount(shopDealRepository.countActiveDeals(shop.getId(), Instant.now()));
                    return response;
                })
                .filter(r -> r.getDistanceKm() <= radiusKm) // Exact radius filter
                .sorted(Comparator.comparingDouble(ShopProfileResponse::getDistanceKm))
                .toList();
    }

    /**
     * Search products across nearby verified shops.
     */
    @Transactional
    public List<ShopProductResponse> searchProductsNearby(String query, BigDecimal lat, BigDecimal lon, double radiusKm, String sortBy) {
        if (query == null || query.isBlank()) return Collections.emptyList();

        // Record search event (anonymous)
        recordSearchEvent(query, lat, lon);

        // Find nearby verified shops first
        double latDelta = radiusKm / 111.0;
        double lonDelta = radiusKm / (111.0 * Math.cos(Math.toRadians(lat.doubleValue())));

        List<NearbyShop> nearbyShops = nearbyShopRepository.findVerifiedShopsInBoundingBox(
                lat.subtract(BigDecimal.valueOf(latDelta)),
                lat.add(BigDecimal.valueOf(latDelta)),
                lon.subtract(BigDecimal.valueOf(lonDelta)),
                lon.add(BigDecimal.valueOf(lonDelta))
        );

        if (nearbyShops.isEmpty()) return Collections.emptyList();

        List<UUID> shopIds = nearbyShops.stream().map(NearbyShop::getId).toList();
        Map<UUID, NearbyShop> shopMap = nearbyShops.stream().collect(Collectors.toMap(NearbyShop::getId, s -> s));

        // Search products in those shops
        List<ShopProductOffer> results = shopProductOfferRepository.searchOffersInShops(shopIds, query.trim());

        return results.stream()
                .map(offer -> {
                    ShopProductResponse response = ShopProductResponse.fromEntity(offer);
                    NearbyShop shop = shopMap.get(offer.getShop().getId());
                    if (shop != null) {
                        double distance = calculateDistance(lat.doubleValue(), lon.doubleValue(),
                                shop.getLatitude().doubleValue(), shop.getLongitude().doubleValue());
                        response.setDistanceKm(Math.round(distance * 10.0) / 10.0);
                        response.setShopName(shop.getName());
                    }
                    return response;
                })
                .sorted(getProductComparator(sortBy))
                .limit(50)
                .toList();
    }

    /**
     * Get shop profile with deals and product count for customer view.
     */
    @Transactional
    public ShopProfileResponse getShopProfile(UUID shopId, BigDecimal userLat, BigDecimal userLon) {
        NearbyShop shop = nearbyShopRepository.findById(shopId)
                .orElseThrow(() -> new com.homestock.core.exception.ResourceNotFoundException("Shop not found"));

        // Record anonymous view
        recordShopView(shop);

        ShopProfileResponse response = ShopProfileResponse.fromEntity(shop);

        if (userLat != null && userLon != null) {
            double distance = calculateDistance(userLat.doubleValue(), userLon.doubleValue(),
                    shop.getLatitude().doubleValue(), shop.getLongitude().doubleValue());
            response.setDistanceKm(Math.round(distance * 10.0) / 10.0);
        }

        response.setActiveDealCount(shopDealRepository.countActiveDeals(shopId, Instant.now()));
        return response;
    }

    /**
     * Get active deals for a shop (customer-facing).
     */
    public List<ShopDealResponse> getShopActiveDeals(UUID shopId) {
        return shopDealRepository.findActiveDeals(shopId, Instant.now()).stream()
                .map(ShopDealResponse::fromEntity)
                .toList();
    }

    /**
     * Get products for a shop (customer-facing — no stock quantities).
     */
    public List<ShopProductResponse> getShopProductsForCustomer(UUID shopId) {
        return shopProductOfferRepository.findByShopIdOrderByRawProductNameAsc(shopId).stream()
                .map(ShopProductResponse::fromEntity)
                .toList();
    }

    // ═══════════════════════════════════════════
    // Helpers
    // ═══════════════════════════════════════════

    private void recordSearchEvent(String query, BigDecimal lat, BigDecimal lon) {
        try {
            ShopSearchEvent event = ShopSearchEvent.builder()
                    .searchQuery(query.trim())
                    .normalizedQuery(query.trim().toLowerCase())
                    .latitude(lat)
                    .longitude(lon)
                    .searchedAt(Instant.now())
                    .build();
            shopSearchEventRepository.save(event);
        } catch (Exception e) {
            log.warn("Failed to record search event: {}", e.getMessage());
        }
    }

    private void recordShopView(NearbyShop shop) {
        try {
            ShopProductView view = ShopProductView.builder()
                    .shop(shop)
                    .viewedAt(Instant.now())
                    .build();
            shopProductViewRepository.save(view);
        } catch (Exception e) {
            log.warn("Failed to record shop view: {}", e.getMessage());
        }
    }

    private Comparator<ShopProductResponse> getProductComparator(String sortBy) {
        if (sortBy == null) sortBy = "NEAREST";
        return switch (sortBy.toUpperCase()) {
            case "LOWEST_PRICE" -> Comparator.comparing(
                    r -> r.getEffectivePrice() != null ? r.getEffectivePrice() : BigDecimal.valueOf(999999),
                    Comparator.naturalOrder());
            case "BEST_DEAL" -> Comparator.comparing(ShopProductResponse::getHasActiveOffer,
                    Comparator.reverseOrder());
            default -> Comparator.comparing(
                    r -> r.getDistanceKm() != null ? r.getDistanceKm() : 999.0,
                    Comparator.naturalOrder());
        };
    }

    /**
     * Haversine distance calculation.
     */
    private double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                   Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                   Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return EARTH_RADIUS_KM * c;
    }
}
