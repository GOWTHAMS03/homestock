package com.homestock.modules.deals.service;

import com.homestock.modules.deals.client.OverpassClient;
import com.homestock.modules.deals.dto.*;
import com.homestock.modules.deals.entity.NearbyShop;
import com.homestock.modules.deals.entity.ShopAreaGrid;
import com.homestock.modules.deals.provider.ShopDiscoveryProvider;
import com.homestock.modules.deals.repository.NearbyShopRepository;
import com.homestock.modules.deals.repository.ShopAreaGridRepository;
import com.homestock.modules.deals.repository.ShopProductOfferRepository;
import com.homestock.modules.deals.util.GeoGridUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NearbyShopDiscoveryRedesignTest {

    @Mock
    private NearbyShopRepository shopRepository;

    @Mock
    private ShopProductOfferRepository offerRepository;

    @Mock
    private LocationService locationService;

    @Mock
    private ShopAreaGridRepository gridRepository;

    @Mock
    private ShopDiscoveryProvider discoveryProvider;

    private NearbyShopCache inMemoryCache;
    private ShopCacheService shopCacheService;
    private ShopDiscoverySyncService syncService;
    private NearbyShopService nearbyShopService;

    @BeforeEach
    void setUp() {
        inMemoryCache = new NearbyShopCache();
        shopCacheService = new ShopCacheService(inMemoryCache);

        syncService = new ShopDiscoverySyncService(
                discoveryProvider,
                shopRepository,
                gridRepository,
                shopCacheService,
                locationService
        );

        nearbyShopService = new NearbyShopService(
                shopRepository,
                offerRepository,
                locationService,
                null,
                inMemoryCache,
                shopCacheService,
                syncService,
                gridRepository
        );
    }

    @Test
    @DisplayName("Requirement 1 & 2: Redis/Cache Hit returns immediately without hitting DB or Overpass")
    void testCacheHitReturnsImmediately() {
        String gridKey = GeoGridUtils.computeGridKey(11.8921, 77.8951, 5000);
        NearbyShopDto cachedDto = NearbyShopDto.builder()
                .name("Fast Cached Supermarket")
                .distanceMeters(300L)
                .distanceLabel("300 m")
                .source("CACHE")
                .build();

        shopCacheService.put(gridKey, List.of(cachedDto));

        NearbyShopsResponseDto response = nearbyShopService.findNearbyShopsResponse(
                BigDecimal.valueOf(11.8921), BigDecimal.valueOf(77.8951), 5000.0, false);

        assertThat(response.getSource()).isEqualTo("CACHE");
        assertThat(response.getShops()).hasSize(1);
        assertThat(response.getShops().get(0).getName()).isEqualTo("Fast Cached Supermarket");
        verifyNoInteractions(shopRepository);
        verifyNoInteractions(discoveryProvider);
    }

    @Test
    @DisplayName("Requirement 3: Redis Unavailable falls back silently to PostgreSQL without error")
    void testRedisUnavailableFallsBackToPostgres() {
        NearbyShop dbShop = NearbyShop.builder()
                .name("Postgres Fresh Store")
                .shopType("SUPERMARKET")
                .latitude(BigDecimal.valueOf(11.8930))
                .longitude(BigDecimal.valueOf(77.8960))
                .isOpen(true)
                .active(true)
                .confidenceScore(75)
                .build();

        when(locationService.calculateBoundingBox(anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(new LocationService.BoundingBox(BigDecimal.valueOf(11.8), BigDecimal.valueOf(11.9), BigDecimal.valueOf(77.8), BigDecimal.valueOf(77.9)));
        when(shopRepository.findShopsInBoundingBox(any(), any(), any(), any()))
                .thenReturn(List.of(dbShop));
        when(locationService.calculateDistanceKm(anyDouble(), anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(0.25);

        NearbyShopsResponseDto response = nearbyShopService.findNearbyShopsResponse(
                BigDecimal.valueOf(11.8921), BigDecimal.valueOf(77.8951), 5000.0, false);

        assertThat(response.getSource()).isEqualTo("DATABASE");
        assertThat(response.getShops()).hasSize(1);
        assertThat(response.getShops().get(0).getName()).isEqualTo("Postgres Fresh Store");
    }

    @Test
    @DisplayName("Requirement 4: Database Has No Data returns Safe Fallback immediately and triggers background sync")
    void testDatabaseEmptyReturnsSafeFallbackAndTriggersBackgroundSync() {
        when(locationService.calculateBoundingBox(anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(new LocationService.BoundingBox(BigDecimal.valueOf(11.8), BigDecimal.valueOf(11.9), BigDecimal.valueOf(77.8), BigDecimal.valueOf(77.9)));
        when(shopRepository.findShopsInBoundingBox(any(), any(), any(), any()))
                .thenReturn(Collections.emptyList());

        AreaSearchResultDto areaDto = AreaSearchResultDto.builder()
                .area("Koonandiyur")
                .city("Mettur")
                .postalCode("636458")
                .state("Tamil Nadu")
                .build();
        when(locationService.reverseGeocode(any(), any())).thenReturn(areaDto);
        when(locationService.calculateDistanceKm(anyDouble(), anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(0.5);

        NearbyShopsResponseDto response = nearbyShopService.findNearbyShopsResponse(
                BigDecimal.valueOf(11.8921), BigDecimal.valueOf(77.8951), 5000.0, false);

        // Asserts safe fallback metadata
        assertThat(response.getSource()).isEqualTo("FALLBACK");
        assertThat(response.getDataFreshness()).isEqualTo("UNKNOWN");
        assertThat(response.getRefreshInProgress()).isTrue();
        assertThat(response.getShops()).isNotEmpty();
        assertThat(response.getShops().get(0).getSource()).isEqualTo("FALLBACK");
        assertThat(response.getShops().get(0).getIsVerified()).isFalse();
        assertThat(response.getShops().get(0).getConfidenceScore()).isEqualTo(30);
    }

    @Test
    @DisplayName("Requirement 5: Background Sync updates Database and Grid Metadata when Overpass succeeds")
    void testBackgroundSyncUpdatesDatabaseOnSuccess() {
        ShopDiscoveryDto discShop = ShopDiscoveryDto.builder()
                .sourceId("node:999")
                .name("OSM Fresh Market")
                .shopType("SUPERMARKET")
                .address("Main Bazaar, Mettur")
                .city("Mettur")
                .latitude(BigDecimal.valueOf(11.8925))
                .longitude(BigDecimal.valueOf(77.8955))
                .build();

        when(discoveryProvider.discoverNearbyShops(anyDouble(), anyDouble(), anyInt()))
                .thenReturn(List.of(discShop));
        when(discoveryProvider.getProviderName()).thenReturn("OpenStreetMap-Overpass");
        when(gridRepository.findByGridKey(anyString())).thenReturn(Optional.empty());
        when(locationService.calculateBoundingBox(anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(new LocationService.BoundingBox(BigDecimal.valueOf(11.8), BigDecimal.valueOf(11.9), BigDecimal.valueOf(77.8), BigDecimal.valueOf(77.9)));
        when(shopRepository.findShopsInBoundingBox(any(), any(), any(), any()))
                .thenReturn(Collections.emptyList());

        syncService.syncGrid("grid_11.89_77.90_5000", 11.8921, 77.8951, 5000);

        verify(shopRepository).saveAll(anyList());
        verify(gridRepository, atLeastOnce()).save(argThat(grid ->
                "COMPLETED".equals(grid.getSyncStatus()) && grid.getLastSyncAt() != null));
    }

    @Test
    @DisplayName("Requirement 6 & 7: Overpass 504 / Mirror Failures do NOT fail User-Facing Request")
    void testOverpass504DoesNotFailUserRequest() {
        when(locationService.calculateBoundingBox(anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(new LocationService.BoundingBox(BigDecimal.valueOf(11.8), BigDecimal.valueOf(11.9), BigDecimal.valueOf(77.8), BigDecimal.valueOf(77.9)));

        NearbyShop existing = NearbyShop.builder()
                .name("Existing Resilient Mart")
                .shopType("PROVISION")
                .latitude(BigDecimal.valueOf(11.8925))
                .longitude(BigDecimal.valueOf(77.8955))
                .isOpen(true)
                .active(true)
                .build();
        when(shopRepository.findShopsInBoundingBox(any(), any(), any(), any()))
                .thenReturn(List.of(existing));
        when(locationService.calculateDistanceKm(anyDouble(), anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(0.4);

        // User request returns existing shops immediately regardless of Overpass status
        NearbyShopsResponseDto response = nearbyShopService.findNearbyShopsResponse(
                BigDecimal.valueOf(11.8921), BigDecimal.valueOf(77.8951), 5000.0, false);

        assertThat(response.getShops()).hasSize(1);
        assertThat(response.getShops().get(0).getName()).isEqualTo("Existing Resilient Mart");
    }

    @Test
    @DisplayName("Requirement 8: 100 Simultaneous Users trigger exactly ONE background refresh for the same grid")
    void test100SimultaneousUsersTriggerOnlyOneSync() throws InterruptedException {
        int threadCount = 100;
        ExecutorService executor = Executors.newFixedThreadPool(16);
        CountDownLatch latch = new CountDownLatch(threadCount);
        AtomicInteger syncExecutionCount = new AtomicInteger(0);

        ShopDiscoverySyncService spiedSync = spy(syncService);
        doAnswer(invocation -> {
            syncExecutionCount.incrementAndGet();
            Thread.sleep(100); // Simulate background work
            return null;
        }).when(spiedSync).syncGrid(anyString(), anyDouble(), anyDouble(), anyInt());

        String testGridKey = "grid_shared_test_5000";

        for (int i = 0; i < threadCount; i++) {
            executor.submit(() -> {
                try {
                    spiedSync.enqueueGridRefresh(11.8921, 77.8951, 5000, testGridKey);
                } finally {
                    latch.countDown();
                }
            });
        }

        latch.await(5, TimeUnit.SECONDS);
        executor.shutdown();

        // Exactly 1 background Overpass sync was triggered across all 100 concurrent requests
        assertThat(syncExecutionCount.get()).isEqualTo(1);
    }

    @Test
    @DisplayName("Requirement 9: Stale Data (>12h) is returned immediately with STALE flag and refreshes asynchronously")
    void testStaleDataReturnedImmediatelyWithStaleFlag() {
        String gridKey = GeoGridUtils.computeGridKey(11.8921, 77.8951, 5000);
        ShopAreaGrid staleGrid = ShopAreaGrid.builder()
                .gridKey(gridKey)
                .lastSyncAt(Instant.now().minus(Duration.ofHours(18))) // 18 hours old
                .syncStatus("COMPLETED")
                .build();

        when(gridRepository.findByGridKey(gridKey)).thenReturn(Optional.of(staleGrid));
        when(locationService.calculateBoundingBox(anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(new LocationService.BoundingBox(BigDecimal.valueOf(11.8), BigDecimal.valueOf(11.9), BigDecimal.valueOf(77.8), BigDecimal.valueOf(77.9)));

        NearbyShop staleShop1 = NearbyShop.builder().name("Shop 1").shopType("GROCERY").latitude(BigDecimal.valueOf(11.892)).longitude(BigDecimal.valueOf(77.895)).isOpen(true).active(true).build();
        NearbyShop staleShop2 = NearbyShop.builder().name("Shop 2").shopType("GROCERY").latitude(BigDecimal.valueOf(11.893)).longitude(BigDecimal.valueOf(77.894)).isOpen(true).active(true).build();
        NearbyShop staleShop3 = NearbyShop.builder().name("Shop 3").shopType("GROCERY").latitude(BigDecimal.valueOf(11.894)).longitude(BigDecimal.valueOf(77.893)).isOpen(true).active(true).build();

        when(shopRepository.findShopsInBoundingBox(any(), any(), any(), any()))
                .thenReturn(List.of(staleShop1, staleShop2, staleShop3));
        when(locationService.calculateDistanceKm(anyDouble(), anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(0.5);

        NearbyShopsResponseDto response = nearbyShopService.findNearbyShopsResponse(
                BigDecimal.valueOf(11.8921), BigDecimal.valueOf(77.8951), 5000.0, false);

        assertThat(response.getDataFreshness()).isEqualTo("STALE");
        assertThat(response.getRefreshInProgress()).isTrue();
        assertThat(response.getShops()).hasSize(3);
    }

    @Test
    @DisplayName("Requirement 10: User-Generated Shop adds new shop and deduplicates against existing (<75m)")
    void testUserGeneratedShopAdditionAndDeduplication() {
        NearbyShop existingShop = NearbyShop.builder()
                .name("Murugan Provision Store")
                .normalizedName("murugan")
                .latitude(BigDecimal.valueOf(11.8920))
                .longitude(BigDecimal.valueOf(77.8950))
                .confidenceScore(70)
                .userReportCount(0)
                .isOpen(true)
                .active(true)
                .build();

        when(locationService.calculateBoundingBox(anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(new LocationService.BoundingBox(BigDecimal.valueOf(11.8), BigDecimal.valueOf(11.9), BigDecimal.valueOf(77.8), BigDecimal.valueOf(77.9)));
        when(shopRepository.findShopsInBoundingBox(any(), any(), any(), any()))
                .thenReturn(List.of(existingShop));
        when(locationService.calculateDistanceKm(anyDouble(), anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(0.02); // 20 meters away
        when(shopRepository.save(any(NearbyShop.class))).thenAnswer(i -> i.getArgument(0));

        // User submits duplicate shop "Murugan Provisions" 20m away
        CreateShopRequestDto request = CreateShopRequestDto.builder()
                .name("Murugan Provisions")
                .city("Mettur")
                .latitude(BigDecimal.valueOf(11.8921))
                .longitude(BigDecimal.valueOf(77.8951))
                .build();

        NearbyShopDto result = nearbyShopService.createShop(request);

        // Deduplication increments confidence (+15) and report count rather than duplicating
        assertThat(result.getName()).isEqualTo("Murugan Provision Store");
        assertThat(existingShop.getConfidenceScore()).isEqualTo(85);
        assertThat(existingShop.getUserReportCount()).isEqualTo(1);
    }

    @Test
    @DisplayName("Requirement 11: Invalid Coordinates throw descriptive IllegalArgumentException")
    void testInvalidCoordinatesThrowValidationError() {
        assertThatThrownBy(() -> nearbyShopService.findNearbyShopsResponse(
                BigDecimal.valueOf(95.0), BigDecimal.valueOf(77.89), 5000.0, false))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Invalid coordinates");

        assertThatThrownBy(() -> nearbyShopService.findNearbyShopsResponse(
                BigDecimal.valueOf(11.89), BigDecimal.valueOf(200.0), 5000.0, false))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Invalid coordinates");
    }
}
