package com.homestock.modules.deals;

import com.homestock.modules.deals.dto.*;
import com.homestock.modules.deals.entity.NearbyShop;
import com.homestock.modules.deals.entity.ShopProductOffer;
import com.homestock.modules.deals.provider.LocalShopDealProvider;
import com.homestock.modules.deals.provider.OnlineDealProviderFactory;
import com.homestock.modules.deals.repository.NearbyShopRepository;
import com.homestock.modules.deals.repository.ShopProductOfferRepository;
import com.homestock.modules.deals.repository.UserLocationPreferenceRepository;
import com.homestock.modules.deals.service.DealBasketOptimizer;
import com.homestock.modules.deals.service.GeminiDealAiService;
import com.homestock.modules.deals.service.LocationService;
import com.homestock.modules.deals.service.NearbyShopService;
import com.homestock.modules.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class LocationAndNearbyShopServiceTest {

    @Mock
    private NearbyShopRepository shopRepository;

    @Mock
    private ShopProductOfferRepository offerRepository;

    @Mock
    private UserLocationPreferenceRepository preferenceRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private LocalShopDealProvider localDealProvider;

    @Mock
    private OnlineDealProviderFactory onlineProviderFactory;

    private LocationService locationService;
    private NearbyShopService nearbyShopService;
    private GeminiDealAiService geminiDealAiService;
    private DealBasketOptimizer basketOptimizer;

    @BeforeEach
    void setUp() {
        locationService = new LocationService(preferenceRepository, userRepository);
        nearbyShopService = new NearbyShopService(shopRepository, offerRepository, locationService);
        geminiDealAiService = new GeminiDealAiService();
        basketOptimizer = new DealBasketOptimizer(nearbyShopService, localDealProvider, onlineProviderFactory, geminiDealAiService);
    }

    @Test
    @DisplayName("Haversine Distance: accurately computes great-circle distance between coordinates")
    void testHaversineDistance() {
        // Mettur Dam (11.7968, 77.8013) to Mettur RS (11.7925, 77.8095)
        double distance = locationService.calculateDistanceKm(11.7968, 77.8013, 11.7925, 77.8095);
        assertThat(distance).isGreaterThan(0.5);
        assertThat(distance).isLessThan(2.0);

        // Same point distance should be 0.0
        double selfDistance = locationService.calculateDistanceKm(11.7968, 77.8013, 11.7968, 77.8013);
        assertThat(selfDistance).isEqualTo(0.0);
    }

    @Test
    @DisplayName("Bounding Box: produces valid coordinate boundaries for radius query")
    void testBoundingBoxCalculation() {
        LocationService.BoundingBox bbox = locationService.calculateBoundingBox(11.7968, 77.8013, 5.0);
        assertThat(bbox.minLat()).isLessThan(BigDecimal.valueOf(11.7968));
        assertThat(bbox.maxLat()).isGreaterThan(BigDecimal.valueOf(11.7968));
        assertThat(bbox.minLon()).isLessThan(BigDecimal.valueOf(77.8013));
        assertThat(bbox.maxLon()).isGreaterThan(BigDecimal.valueOf(77.8013));
    }

    @Test
    @DisplayName("Nearby Shop Discovery: filters non-grocery businesses and sorts by distance")
    void testNearbyShopDiscovery() {
        UUID shop1Id = UUID.randomUUID();
        NearbyShop grocery = NearbyShop.builder()
                .name("Local Supermarket")
                .shopType("SUPERMARKET")
                .latitude(BigDecimal.valueOf(11.7968))
                .longitude(BigDecimal.valueOf(77.8013))
                .isOpen(true)
                .isVerified(true)
                .build();
        grocery.setId(shop1Id);

        NearbyShop nonGrocery = NearbyShop.builder()
                .name("City Electronics")
                .shopType("ELECTRONICS") // Should be filtered out
                .latitude(BigDecimal.valueOf(11.7970))
                .longitude(BigDecimal.valueOf(77.8015))
                .isOpen(true)
                .isVerified(true)
                .build();

        when(shopRepository.findShopsInBoundingBox(any(), any(), any(), any()))
                .thenReturn(List.of(grocery, nonGrocery));
        when(offerRepository.findByShopId(shop1Id)).thenReturn(List.of());

        List<NearbyShopDto> result = nearbyShopService.findNearbyShops(
                BigDecimal.valueOf(11.7968), BigDecimal.valueOf(77.8013), 5.0);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getName()).isEqualTo("Local Supermarket");
        assertThat(result.get(0).getShopType()).isEqualTo("SUPERMARKET");
    }

    @Test
    @DisplayName("Shop Presence != Product Availability: verified items show prices, unverified do not invent prices")
    void testShopPresenceDoesNotImplyAvailability() {
        UUID shopId = UUID.randomUUID();
        NearbyShop shop = NearbyShop.builder()
                .name("Local Supermarket")
                .shopType("SUPERMARKET")
                .latitude(BigDecimal.valueOf(11.7968))
                .longitude(BigDecimal.valueOf(77.8013))
                .isOpen(true)
                .isVerified(true)
                .build();
        shop.setId(shopId);

        ShopProductOffer riceOffer = ShopProductOffer.builder()
                .shop(shop)
                .rawProductName("Ponni Raw Rice 5 KG")
                .normalizedName("Ponni Rice")
                .price(BigDecimal.valueOf(275.00))
                .effectivePrice(BigDecimal.valueOf(275.00))
                .pricePerUnit(BigDecimal.valueOf(55.00))
                .pricePerUnitLabel("₹55.00 / KG")
                .stockStatus("IN_STOCK")
                .source("SHOP_CATALOG")
                .confidence("HIGH")
                .lastVerifiedAt(Instant.now())
                .build();

        when(shopRepository.findById(shopId)).thenReturn(Optional.of(shop));
        when(offerRepository.findByShopId(shopId)).thenReturn(List.of(riceOffer));

        Map<String, Object> deals = nearbyShopService.getShopDeals(shopId);
        assertThat(deals).containsKey("confirmedDeals");

        @SuppressWarnings("unchecked")
        List<ShopDealDto> confirmed = (List<ShopDealDto>) deals.get("confirmedDeals");
        assertThat(confirmed).hasSize(1);
        assertThat(confirmed.get(0).getProductName()).isEqualTo("Ponni Rice");
        assertThat(confirmed.get(0).getPrice()).isEqualTo(BigDecimal.valueOf(275.00));
        assertThat(confirmed.get(0).getFreshnessStatus()).isEqualTo("LIVE");
    }

    @Test
    @DisplayName("AI Failure Protection: Gemini fallback correctly extracts Tamil/Tanglish entities")
    void testGeminiDealAiFallback() {
        // Tanglish phrase: "5 kilo ponni arisi cheap ah enga iruku?"
        GeminiDealAiService.ParsedDealIntent parsed = geminiDealAiService.buildFallbackIntent("5 kilo ponni arisi cheap ah enga iruku?");
        assertThat(parsed.getProductName()).isEqualTo("Ponni Rice");
        assertThat(parsed.getQuantity()).isEqualByComparingTo(BigDecimal.valueOf(5));
        assertThat(parsed.getUnit()).isEqualTo("KG");

        // Tamil grocery phrase: "2 litre ennai price"
        GeminiDealAiService.ParsedDealIntent parsedOil = geminiDealAiService.buildFallbackIntent("2 litre ennai price");
        assertThat(parsedOil.getProductName()).isEqualTo("Sunflower Oil");
        assertThat(parsedOil.getQuantity()).isEqualByComparingTo(BigDecimal.valueOf(2));
        assertThat(parsedOil.getUnit()).isEqualTo("L");

        // Shopping list intent: "best deal for my shopping list"
        GeminiDealAiService.ParsedDealIntent parsedBasket = geminiDealAiService.buildFallbackIntent("best deal for my shopping list");
        assertThat(parsedBasket.getIntent()).isEqualTo("FIND_BEST_BASKET");
    }

    @Test
    @DisplayName("Basket Optimization: computes single store convenience and multi-store split trade-off")
    void testBasketOptimization() {
        UUID shopId = UUID.randomUUID();
        NearbyShop shopEntity = NearbyShop.builder()
                .name("Local Supermarket")
                .shopType("SUPERMARKET")
                .latitude(BigDecimal.valueOf(11.7968))
                .longitude(BigDecimal.valueOf(77.8013))
                .isOpen(true)
                .isVerified(true)
                .build();
        shopEntity.setId(shopId);

        when(shopRepository.findShopsInBoundingBox(any(), any(), any(), any()))
                .thenReturn(List.of(shopEntity));
        when(offerRepository.findByShopId(shopId)).thenReturn(List.of());

        BasketOptimizationRequestDto req = BasketOptimizationRequestDto.builder()
                .items(List.of(
                        BasketOptimizationRequestDto.BasketItemQuery.builder()
                                .itemName("Ponni Rice")
                                .quantity(BigDecimal.valueOf(5))
                                .unit("KG")
                                .build()
                ))
                .latitude(BigDecimal.valueOf(11.7968))
                .longitude(BigDecimal.valueOf(77.8013))
                .radiusKm(5.0)
                .includeTravelCost(false)
                .build();

        when(localDealProvider.searchLocalDeals(any(), any(), any(), any(), any(), any()))
                .thenReturn(List.of(
                        ShopDealDto.builder()
                                .shopName("Local Supermarket")
                                .shopType("SUPERMARKET")
                                .productName("Ponni Rice")
                                .price(BigDecimal.valueOf(275.00))
                                .effectivePrice(BigDecimal.valueOf(275.00))
                                .isAvailable(true)
                                .build()
                ));

        when(onlineProviderFactory.searchOnlineOffers(any(), any(), any()))
                .thenReturn(List.of(
                        BasketOptimizationResponseDto.OnlineDealOfferDto.builder()
                                .provider("Flipkart")
                                .price(BigDecimal.valueOf(289.00))
                                .effectivePrice(BigDecimal.valueOf(289.00))
                                .build()
                ));

        BasketOptimizationResponseDto result = basketOptimizer.optimizeBasket(req);
        assertThat(result).isNotNull();
        assertThat(result.getItemComparisons()).hasSize(1);
        assertThat(result.getBestSingleStoreOption()).isNotNull();
        assertThat(result.getBestSingleStoreOption().getBasketItemsTotal()).isEqualByComparingTo(BigDecimal.valueOf(275.00));
    }

    @Test
    @DisplayName("Dynamic Shop Discovery: auto-registers hyper-local shops when bounding box is empty")
    void testDynamicShopDiscoveryWhenNoShopsInBoundingBox() {
        when(shopRepository.saveAll(any())).thenAnswer(invocation -> {
            List<NearbyShop> shops = invocation.getArgument(0);
            for (NearbyShop s : shops) {
                if (s.getId() == null) s.setId(UUID.randomUUID());
            }
            return shops;
        });

        List<NearbyShop> discovered = nearbyShopService.discoverAndRegisterLiveShops(11.8486, 77.7512);
        assertThat(discovered).isNotEmpty();
        assertThat(discovered.get(0).getName()).isNotBlank();
        assertThat(discovered.get(0).getLatitude()).isNotNull();
        assertThat(discovered.get(0).getLongitude()).isNotNull();
    }

    @Test
    @DisplayName("Live Reverse Geocode: gracefully returns valid AreaSearchResultDto for coordinates")
    void testLiveReverseGeocodeGracefulHandling() {
        AreaSearchResultDto area = locationService.reverseGeocode(
                BigDecimal.valueOf(11.8486), BigDecimal.valueOf(77.7512));
        assertThat(area).isNotNull();
        assertThat(area.getLatitude()).isEqualByComparingTo(BigDecimal.valueOf(11.8486));
        assertThat(area.getLongitude()).isEqualByComparingTo(BigDecimal.valueOf(77.7512));
        assertThat(area.getDisplayName()).isNotBlank();
    }

    @Test
    @DisplayName("UserLocationRequest: validates timestamp window and provides privacy-safe masked coordinates")
    void testUserLocationRequestValidationAndMasking() {
        UserLocationRequest validReq = UserLocationRequest.builder()
                .latitude(BigDecimal.valueOf(11.7968))
                .longitude(BigDecimal.valueOf(77.8013))
                .accuracyMeters(14.5)
                .timestamp(Instant.now().minusSeconds(60))
                .build();

        assertThat(validReq.isValidTimestamp()).isTrue();
        String masked = validReq.getMaskedLocation();
        assertThat(masked).contains("lat=11.79***");
        assertThat(masked).contains("lon=77.80***");
        assertThat(masked).doesNotContain("11.7968"); // Exact precision redacted
        assertThat(masked).doesNotContain("77.8013");

        UserLocationRequest ancientReq = UserLocationRequest.builder()
                .latitude(BigDecimal.valueOf(11.7968))
                .longitude(BigDecimal.valueOf(77.8013))
                .accuracyMeters(14.5)
                .timestamp(Instant.now().minus(java.time.Duration.ofDays(2)))
                .build();

        assertThat(ancientReq.isValidTimestamp()).isFalse();
    }
}
