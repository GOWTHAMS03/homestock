package com.homestock.modules.deals.service;

import com.homestock.modules.deals.dto.NearbyShopDto;
import com.homestock.modules.deals.dto.ShopDiscoveryDto;
import com.homestock.modules.deals.entity.NearbyShop;
import com.homestock.modules.deals.entity.ShopAreaGrid;
import com.homestock.modules.deals.provider.ShopDiscoveryProvider;
import com.homestock.modules.deals.repository.NearbyShopRepository;
import com.homestock.modules.deals.repository.ShopAreaGridRepository;
import com.homestock.modules.deals.util.GeoGridUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Pattern;

/**
 * Background-Only Synchronization Engine for Nearby Shops.
 * Decouples user-facing API from external Overpass latencies.
 * Guarantees that concurrent requests for the same geographic grid trigger exactly ONE Overpass sync.
 */
@Service
public class ShopDiscoverySyncService {

    private static final Logger log = LoggerFactory.getLogger(ShopDiscoverySyncService.class);

    private static final Pattern PUNCTUATION_PATTERN = Pattern.compile("[^a-zA-Z0-9\\s]");
    private static final Set<String> STOP_WORDS = Set.of(
            "store", "stores", "supermarket", "mart", "shop", "shops", "grocery", "provision", "maligai", "nilayam", "bazaar"
    );

    private final ShopDiscoveryProvider discoveryProvider;
    private final NearbyShopRepository shopRepository;
    private final ShopAreaGridRepository gridRepository;
    private final ShopCacheService shopCacheService;
    private final LocationService locationService;

    // Concurrency guard: Ensures only 1 background sync runs per geographic grid
    private final Map<String, Boolean> activeSyncGrids = new ConcurrentHashMap<>();

    @Autowired
    public ShopDiscoverySyncService(ShopDiscoveryProvider discoveryProvider,
                                    NearbyShopRepository shopRepository,
                                    ShopAreaGridRepository gridRepository,
                                    ShopCacheService shopCacheService,
                                    LocationService locationService) {
        this.discoveryProvider = discoveryProvider;
        this.shopRepository = shopRepository;
        this.gridRepository = gridRepository;
        this.shopCacheService = shopCacheService;
        this.locationService = locationService;
    }

    /**
     * Checks if a background sync is currently in progress for this grid.
     */
    public boolean isSyncInProgress(String gridKey) {
        return activeSyncGrids.containsKey(gridKey);
    }

    /**
     * Asynchronously enqueues a grid refresh task. Returns immediately.
     * Prevents 100 concurrent users from triggering duplicate requests.
     */
    @Async
    public CompletableFuture<Void> enqueueGridRefresh(double latitude, double longitude, int radiusMeters, String gridKey) {
        if (gridKey == null) {
            gridKey = GeoGridUtils.computeGridKey(latitude, longitude, radiusMeters);
        }

        // Concurrency Guard: Atomic check-and-set
        if (activeSyncGrids.putIfAbsent(gridKey, Boolean.TRUE) != null) {
            log.debug("[BACKGROUND_SHOP_SYNC] Duplicate sync suppressed for grid: {} (already in progress)", gridKey);
            return CompletableFuture.completedFuture(null);
        }

        try {
            syncGrid(gridKey, latitude, longitude, radiusMeters);
        } catch (Exception e) {
            log.warn("[BACKGROUND_SHOP_SYNC] Unexpected error executing sync for grid {}: {}", gridKey, e.getMessage());
        } finally {
            activeSyncGrids.remove(gridKey);
        }

        return CompletableFuture.completedFuture(null);
    }

    /**
     * Performs durable synchronization of shop data for a geographic grid.
     */
    @Transactional
    public void syncGrid(String gridKey, double latitude, double longitude, int radiusMeters) {
        long startTime = System.currentTimeMillis();
        Instant now = Instant.now();

        // 1. Record / Claim sync state in database
        ShopAreaGrid gridRecord = gridRepository.findByGridKey(gridKey)
                .orElseGet(() -> ShopAreaGrid.builder()
                        .gridKey(gridKey)
                        .geohash(GeoGridUtils.encodeGeohash(latitude, longitude, 6))
                        .centerLat(GeoGridUtils.computeCenterLat(latitude))
                        .centerLon(GeoGridUtils.computeCenterLon(longitude))
                        .radiusMeters(radiusMeters)
                        .syncStatus("PENDING")
                        .shopCount(0)
                        .syncAttempts(0)
                        .build());

        gridRecord.setSyncStatus("SYNCING");
        gridRecord.setSyncAttempts(gridRecord.getSyncAttempts() + 1);
        gridRepository.save(gridRecord);

        int fetchedCount = 0;
        int insertedCount = 0;
        int updatedCount = 0;
        int duplicateCount = 0;

        try {
            // 2. Fetch POIs from provider (Overpass)
            List<ShopDiscoveryDto> discoveredShops = discoveryProvider.discoverNearbyShops(
                    latitude, longitude, radiusMeters);
            fetchedCount = discoveredShops.size();

            // Background Progressive Radius Expansion if needed (< 3 shops and radius < 5000m)
            int effectiveRadius = radiusMeters;
            if (fetchedCount < 3 && radiusMeters < 5000) {
                effectiveRadius = 5000;
                log.info("[BACKGROUND_SHOP_SYNC] Expanding search radius to {}m for grid {}", effectiveRadius, gridKey);
                List<ShopDiscoveryDto> expanded = discoveryProvider.discoverNearbyShops(
                        latitude, longitude, effectiveRadius);
                if (!expanded.isEmpty()) {
                    discoveredShops = expanded;
                    fetchedCount = discoveredShops.size();
                }
            }

            // 3. Process, Deduplicate and Persist
            if (!discoveredShops.isEmpty()) {
                // Fetch existing shops in bounding box for proximity deduplication
                LocationService.BoundingBox bbox = locationService.calculateBoundingBox(
                        latitude, longitude, effectiveRadius / 1000.0);
                List<NearbyShop> existingShops = shopRepository.findShopsInBoundingBox(
                        bbox.minLat(), bbox.maxLat(), bbox.minLon(), bbox.maxLon());

                List<NearbyShop> toSave = new ArrayList<>();

                for (ShopDiscoveryDto disc : discoveredShops) {
                    // Check by sourceId (e.g. osmId)
                    Optional<NearbyShop> bySourceId = disc.getSourceId() != null
                            ? shopRepository.findByOsmId(disc.getSourceId())
                            : Optional.empty();

                    if (bySourceId.isPresent()) {
                        NearbyShop existing = bySourceId.get();
                        // Update existing shop metadata
                        if (disc.getOpeningHours() != null && !disc.getOpeningHours().isBlank()) {
                            existing.setOpeningHours(disc.getOpeningHours());
                        }
                        if (disc.getPhone() != null && !disc.getPhone().isBlank()) {
                            existing.setPhone(disc.getPhone());
                        }
                        existing.setLastOsmSyncAt(now);
                        toSave.add(existing);
                        updatedCount++;
                        continue;
                    }

                    // Proximity & Name deduplication (75 meters threshold)
                    String normalizedDiscName = normalizeShopName(disc.getName());
                    boolean duplicateFound = false;

                    for (NearbyShop existing : existingShops) {
                        double distKm = locationService.calculateDistanceKm(
                                existing.getLatitude().doubleValue(), existing.getLongitude().doubleValue(),
                                disc.getLatitude().doubleValue(), disc.getLongitude().doubleValue()
                        );

                        if (distKm <= 0.075) { // 75 meters
                            String normalizedExistingName = normalizeShopName(existing.getName());
                            if (isNameMatch(normalizedDiscName, normalizedExistingName)) {
                                duplicateFound = true;
                                duplicateCount++;
                                existing.setLastOsmSyncAt(now);
                                if (disc.getSourceId() != null && (existing.getOsmId() == null || existing.getOsmId().isBlank())) {
                                    existing.setOsmId(disc.getSourceId());
                                }
                                toSave.add(existing);
                                break;
                            }
                        }
                    }

                    if (!duplicateFound) {
                        String city = (disc.getCity() != null && !disc.getCity().isBlank()) ? disc.getCity() : "Local Area";
                        String area = disc.getArea() != null ? disc.getArea() : "";
                        String address = (disc.getAddress() != null && !disc.getAddress().isBlank()) ? disc.getAddress() : city;
                        String postalCode = disc.getPostalCode() != null ? disc.getPostalCode() : "";

                        NearbyShop newShop = NearbyShop.builder()
                                .osmId(disc.getSourceId())
                                .name(disc.getName())
                                .normalizedName(normalizedDiscName)
                                .shopType(disc.getShopType() != null ? disc.getShopType() : "GROCERY")
                                .address(address)
                                .area(area)
                                .city(city)
                                .postalCode(postalCode)
                                .latitude(disc.getLatitude())
                                .longitude(disc.getLongitude())
                                .openingHours(disc.getOpeningHours() != null ? disc.getOpeningHours() : "8:00 AM - 9:00 PM")
                                .phone(disc.getPhone())
                                .source("OSM")
                                .sourceId(disc.getSourceId())
                                .confidenceScore(70)
                                .isOpen(true)
                                .isVerified(false)
                                .active(true)
                                .reviewCount(0)
                                .lastOsmSyncAt(now)
                                .build();
                        toSave.add(newShop);
                        insertedCount++;
                    }
                }

                if (!toSave.isEmpty()) {
                    shopRepository.saveAll(toSave);
                }
            }

            // 4. Update Grid Metadata
            int totalShopsInGrid = shopRepository.findShopsInBoundingBox(
                    BigDecimal.valueOf(latitude - 0.03), BigDecimal.valueOf(latitude + 0.03),
                    BigDecimal.valueOf(longitude - 0.03), BigDecimal.valueOf(longitude + 0.03)).size();

            gridRecord.setShopCount(totalShopsInGrid);
            gridRecord.setLastSyncAt(now);
            gridRecord.setSyncStatus("COMPLETED");
            gridRecord.setFailureReason(null);
            gridRepository.save(gridRecord);

            // 5. Invalidate / warm cache so next request hits fresh data
            shopCacheService.evict(gridKey);

            long duration = System.currentTimeMillis() - startTime;
            log.info("[BACKGROUND_SHOP_SYNC] grid={} provider={} duration={}ms fetched={} inserted={} updated={} duplicates={} status=COMPLETED",
                    gridKey, discoveryProvider.getProviderName(), duration, fetchedCount, insertedCount, updatedCount, duplicateCount);

        } catch (Exception e) {
            long duration = System.currentTimeMillis() - startTime;
            log.warn("[BACKGROUND_SHOP_SYNC] grid={} duration={}ms FAILED: {}", gridKey, duration, e.getMessage());
            gridRecord.setSyncStatus("FAILED");
            gridRecord.setFailureReason(e.getMessage());
            gridRepository.save(gridRecord);
        }
    }

    public String normalizeShopName(String name) {
        if (name == null || name.isBlank()) return "";
        String cleaned = PUNCTUATION_PATTERN.matcher(name.toLowerCase().trim()).replaceAll(" ");
        String[] tokens = cleaned.split("\\s+");

        StringBuilder sb = new StringBuilder();
        for (String token : tokens) {
            if (!token.isBlank() && !STOP_WORDS.contains(token)) {
                if (!sb.isEmpty()) sb.append(" ");
                sb.append(token);
            }
        }
        return sb.toString().trim();
    }

    private boolean isNameMatch(String name1, String name2) {
        if (name1.isBlank() || name2.isBlank()) return false;
        if (name1.equals(name2)) return true;
        if (name1.contains(name2) || name2.contains(name1)) return true;

        int editDist = computeLevenshteinDistance(name1, name2);
        int maxLen = Math.max(name1.length(), name2.length());
        return editDist <= Math.max(1, maxLen / 4);
    }

    private int computeLevenshteinDistance(String s1, String s2) {
        int[] costs = new int[s2.length() + 1];
        for (int j = 0; j < costs.length; j++) costs[j] = j;
        for (int i = 1; i <= s1.length(); i++) {
            costs[0] = i;
            int nw = i - 1;
            for (int j = 1; j <= s2.length(); j++) {
                int cj = Math.min(1 + Math.min(costs[j], costs[j - 1]),
                        s1.charAt(i - 1) == s2.charAt(j - 1) ? nw : nw + 1);
                nw = costs[j];
                costs[j] = cj;
            }
        }
        return costs[s2.length()];
    }
}
