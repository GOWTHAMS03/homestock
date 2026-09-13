package com.homestock.modules.deals.service;

import com.homestock.modules.deals.client.OverpassClient;
import com.homestock.modules.deals.dto.NearbyShopDto;
import com.homestock.modules.deals.entity.NearbyShop;
import com.homestock.modules.deals.repository.NearbyShopRepository;
import com.homestock.modules.deals.repository.ShopProductOfferRepository;
import com.homestock.modules.deals.repository.UserLocationPreferenceRepository;
import com.homestock.modules.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NearbyShopDeduplicationAndCacheTest {

    @Mock
    private NearbyShopRepository shopRepository;

    @Mock
    private ShopProductOfferRepository offerRepository;

    @Mock
    private UserLocationPreferenceRepository preferenceRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private OverpassClient overpassClient;

    private LocationService locationService;
    private NearbyShopCache nearbyShopCache;
    private NearbyShopService nearbyShopService;

    @BeforeEach
    void setUp() {
        locationService = new LocationService(preferenceRepository, userRepository);
        nearbyShopCache = new NearbyShopCache();
        nearbyShopService = new NearbyShopService(
                shopRepository,
                offerRepository,
                locationService,
                overpassClient,
                nearbyShopCache
        );
    }

    @Test
    @DisplayName("Deduplication: Merges near-duplicate shops within 75m that share normalized names")
    void testDeduplicateNearbyShops() {
        // Shop 1: "Sri Lakshmi Stores" at (11.7968, 77.8013)
        NearbyShop shop1 = NearbyShop.builder()
                .osmId("node:1001")
                .name("Sri Lakshmi Stores")
                .shopType("GROCERY")
                .address("Main Bazaar Road, Mettur")
                .latitude(BigDecimal.valueOf(11.796800))
                .longitude(BigDecimal.valueOf(77.801300))
                .isVerified(false)
                .build();

        // Shop 2: "Sri Lakshmi Store" only 20 meters away (11.7969, 77.8014) -> should be merged!
        NearbyShop shop2 = NearbyShop.builder()
                .osmId("way:2002")
                .name("Sri Lakshmi Store")
                .shopType("GROCERY")
                .address("Main Bazaar")
                .latitude(BigDecimal.valueOf(11.796950))
                .longitude(BigDecimal.valueOf(77.801400))
                .isVerified(true) // Has verified status, should elevate
                .build();

        // Shop 3: Distinct shop 800 meters away -> should NOT be merged
        NearbyShop shop3 = NearbyShop.builder()
                .osmId("node:3003")
                .name("Murugan Maligai")
                .shopType("PROVISION")
                .address("RS Road")
                .latitude(BigDecimal.valueOf(11.791000))
                .longitude(BigDecimal.valueOf(77.807000))
                .isVerified(false)
                .build();

        List<NearbyShop> deduped = nearbyShopService.deduplicateShops(List.of(shop1, shop2, shop3));

        assertThat(deduped).hasSize(2);
        assertThat(deduped.stream().anyMatch(s -> s.getName().contains("Lakshmi"))).isTrue();
        assertThat(deduped.stream().anyMatch(s -> s.getName().contains("Murugan"))).isTrue();
    }

    @Test
    @DisplayName("Deduplication: Does NOT merge two distinct shops with similar names if far apart (>75m)")
    void testDoNotMergeDistantShopsWithSimilarNames() {
        // "Annapoorna Supermarket" in North Town (11.8000, 77.8000)
        NearbyShop shop1 = NearbyShop.builder()
                .name("Annapoorna Supermarket")
                .shopType("SUPERMARKET")
                .latitude(BigDecimal.valueOf(11.8000))
                .longitude(BigDecimal.valueOf(77.8000))
                .build();

        // "Annapoorna Provision" 2.5 km away in South Town (11.7770, 77.8000)
        NearbyShop shop2 = NearbyShop.builder()
                .name("Annapoorna Provision")
                .shopType("PROVISION")
                .latitude(BigDecimal.valueOf(11.7770))
                .longitude(BigDecimal.valueOf(77.8000))
                .build();

        List<NearbyShop> deduped = nearbyShopService.deduplicateShops(List.of(shop1, shop2));
        assertThat(deduped).hasSize(2); // Retains both distinct stores
    }

    @Test
    @DisplayName("Geospatial Cache: provides hit, expiration, and spatial key generation")
    void testGeospatialCacheOperations() {
        String key = nearbyShopCache.generateKey(11.796812, 77.801345, 2000);
        assertThat(key).isEqualTo("11.797_77.801_2000");

        NearbyShopDto dto = NearbyShopDto.builder()
                .name("Cached Supermarket")
                .distanceMeters(450L)
                .distanceLabel("450 m")
                .build();

        // Put with short TTL
        nearbyShopCache.put(key, List.of(dto), Duration.ofMillis(200));

        // Immediate get should hit
        Optional<List<NearbyShopDto>> cached = nearbyShopCache.get(key);
        assertThat(cached).isPresent();
        assertThat(cached.get().get(0).getName()).isEqualTo("Cached Supermarket");

        // After TTL expires, get should return empty
        try {
            Thread.sleep(250);
        } catch (InterruptedException ignored) {}

        Optional<List<NearbyShopDto>> expired = nearbyShopCache.get(key);
        assertThat(expired).isEmpty();
    }

    @Test
    @DisplayName("Progressive Radius Expansion: auto-expands from 2000m to 5000m when results < 3")
    void testProgressiveRadiusExpansion() {
        // Initial 2000m search returns only 1 shop
        OverpassClient.RawOsmShop shop1 = OverpassClient.RawOsmShop.builder()
                .osmId("node:1")
                .name("Solitary Grocery")
                .shopType("GROCERY")
                .latitude(BigDecimal.valueOf(11.7968))
                .longitude(BigDecimal.valueOf(77.8013))
                .build();

        // 5000m search returns 3 shops
        OverpassClient.RawOsmShop shop2 = OverpassClient.RawOsmShop.builder()
                .osmId("node:2")
                .name("Expanded Supermarket")
                .shopType("SUPERMARKET")
                .latitude(BigDecimal.valueOf(11.8200))
                .longitude(BigDecimal.valueOf(77.8100))
                .build();

        OverpassClient.RawOsmShop shop3 = OverpassClient.RawOsmShop.builder()
                .osmId("node:3")
                .name("Highway Department Store")
                .shopType("DEPARTMENT")
                .latitude(BigDecimal.valueOf(11.8250))
                .longitude(BigDecimal.valueOf(77.8150))
                .build();

        when(shopRepository.findShopsInBoundingBox(any(), any(), any(), any()))
                .thenReturn(Collections.emptyList());

        when(overpassClient.fetchNearbyGroceryShops(11.7968, 77.8013, 2000))
                .thenReturn(List.of(shop1));

        when(overpassClient.fetchNearbyGroceryShops(11.7968, 77.8013, 5000))
                .thenReturn(List.of(shop1, shop2, shop3));

        List<NearbyShopDto> results = nearbyShopService.findNearbyShops(
                BigDecimal.valueOf(11.7968), BigDecimal.valueOf(77.8013), 2000.0, true);

        // Verify expansion was triggered
        verify(overpassClient).fetchNearbyGroceryShops(11.7968, 77.8013, 5000);
        assertThat(results).isNotEmpty();
    }

    @Test
    @DisplayName("Distance Formatting: human-readable labels for meters and kilometers")
    void testDistanceLabels() {
        NearbyShop closeShop = NearbyShop.builder()
                .name("Close Store")
                .shopType("GROCERY")
                .latitude(BigDecimal.valueOf(11.7968 + 0.003)) // ~330m away
                .longitude(BigDecimal.valueOf(77.8013))
                .isOpen(true)
                .build();

        NearbyShop farShop = NearbyShop.builder()
                .name("Far Store")
                .shopType("SUPERMARKET")
                .latitude(BigDecimal.valueOf(11.7968 + 0.015)) // ~1.6km away
                .longitude(BigDecimal.valueOf(77.8013))
                .isOpen(true)
                .build();

        when(shopRepository.findShopsInBoundingBox(any(), any(), any(), any()))
                .thenReturn(List.of(closeShop, farShop));

        List<NearbyShopDto> results = nearbyShopService.findNearbyShops(
                BigDecimal.valueOf(11.7968), BigDecimal.valueOf(77.8013), 5000.0, true);

        assertThat(results).hasSize(2);
        // First shop is closer (<1km)
        assertThat(results.get(0).getDistanceLabel()).endsWith("m");
        // Second shop is further (>=1km)
        assertThat(results.get(1).getDistanceLabel()).endsWith("km");
    }
}

