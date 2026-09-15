package com.homestock.modules.shop.service;

import com.homestock.core.security.ShopSecurityService;
import com.homestock.modules.deals.entity.NearbyShop;
import com.homestock.modules.deals.entity.ShopProductOffer;
import com.homestock.modules.deals.repository.NearbyShopRepository;
import com.homestock.modules.deals.repository.ShopProductOfferRepository;
import com.homestock.modules.shop.dto.demand.*;
import com.homestock.modules.shop.entity.CustomerDemandEvent;
import com.homestock.modules.shop.entity.DemandEventType;
import com.homestock.modules.shop.entity.ShopSubscription;
import com.homestock.modules.shop.entity.SubscriptionPlan;
import com.homestock.modules.shop.repository.CustomerDemandEventRepository;
import com.homestock.modules.shop.repository.ShopSubscriptionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CustomerDemandServiceTest {

    @Mock
    private CustomerDemandEventRepository demandEventRepository;

    @Mock
    private NearbyShopRepository nearbyShopRepository;

    @Mock
    private ShopProductOfferRepository shopProductOfferRepository;

    @Mock
    private ShopSubscriptionRepository subscriptionRepository;

    @Mock
    private ShopSecurityService shopSecurityService;

    @InjectMocks
    private CustomerDemandService demandService;

    private UUID shopId;
    private NearbyShop testShop;
    private SubscriptionPlan paidPlan;
    private SubscriptionPlan freePlan;

    @BeforeEach
    void setUp() {
        shopId = UUID.randomUUID();
        testShop = NearbyShop.builder()
                .name("Kaveri Supermarket")
                .latitude(BigDecimal.valueOf(12.9716))
                .longitude(BigDecimal.valueOf(77.5946))
                .build();
        testShop.setId(shopId);

        paidPlan = SubscriptionPlan.builder()
                .name("STARTER")
                .analyticsEnabled(true)
                .build();
        paidPlan.setId(UUID.randomUUID());

        freePlan = SubscriptionPlan.builder()
                .name("FREE")
                .analyticsEnabled(false)
                .build();
        freePlan.setId(UUID.randomUUID());

        when(shopSecurityService.canManageShop(shopId)).thenReturn(true);
        when(nearbyShopRepository.findById(shopId)).thenReturn(Optional.of(testShop));
    }

    @Test
    @DisplayName("Demand scoring correctly weights event types, recency, and distance")
    void testDemandScoring_withWeightsRecencyAndDistance() {
        ShopSubscription sub = ShopSubscription.builder().shop(testShop).plan(paidPlan).build();
        when(subscriptionRepository.findActiveSubscription(shopId)).thenReturn(Optional.of(sub));

        CustomerDemandEvent e1 = CustomerDemandEvent.builder()
                .eventType(DemandEventType.SEARCH)
                .queryText("Ponni Rice")
                .normalizedQuery("ponni rice")
                .latitude(BigDecimal.valueOf(12.9716))
                .longitude(BigDecimal.valueOf(77.5946))
                .createdAt(Instant.now())
                .build();

        CustomerDemandEvent e2 = CustomerDemandEvent.builder()
                .eventType(DemandEventType.SHOPPING_LIST_ADD)
                .queryText("Ponni Rice")
                .normalizedQuery("ponni rice")
                .latitude(BigDecimal.valueOf(12.9720))
                .longitude(BigDecimal.valueOf(77.5950))
                .createdAt(Instant.now().minus(1, ChronoUnit.DAYS))
                .build();

        CustomerDemandEvent e3 = CustomerDemandEvent.builder()
                .eventType(DemandEventType.NEARBY_SEARCH)
                .queryText("Ponni Rice")
                .normalizedQuery("ponni rice")
                .latitude(BigDecimal.valueOf(12.9716))
                .longitude(BigDecimal.valueOf(77.5946))
                .createdAt(Instant.now())
                .build();

        when(demandEventRepository.findEventsInBoundingBoxAndDateRange(any(), any(), any(), any(), any(), any()))
                .thenReturn(List.of(e1, e2, e3))
                .thenReturn(List.of()); // Previous period

        when(shopProductOfferRepository.findByShopId(shopId)).thenReturn(List.of());
        when(nearbyShopRepository.findVerifiedShopsInBoundingBox(any(), any(), any(), any())).thenReturn(List.of());

        CustomerDemandDashboardResponse response = demandService.getShopDemandDashboard(
                shopId, DemandPeriod.LAST_7_DAYS, 5.0);

        assertThat(response).isNotNull();
        assertThat(response.getTotalDemandSignals()).isEqualTo(3);
        assertThat(response.isGated()).isFalse();
        assertThat(response.getTopDemandedProducts()).hasSize(1);

        ProductDemandItemDto rice = response.getTopDemandedProducts().get(0);
        assertThat(rice.getProductName()).isEqualTo("Ponni Rice");
        // Weights: SEARCH (1.0) + SHOPPING_LIST_ADD (4.0 * decay) + NEARBY_SEARCH (5.0) > 8.0
        assertThat(rice.getDemandScore()).isGreaterThan(8.0);
        assertThat(rice.isInShopCatalog()).isFalse();
        assertThat(rice.isLowDataWarning()).isFalse(); // Exactly 3 signals
    }

    @Test
    @DisplayName("Catalog gap opportunity is identified when high-demand item is missing from shop catalog")
    void testCatalogGapOpportunity_whenItemMissing() {
        ShopSubscription sub = ShopSubscription.builder().shop(testShop).plan(paidPlan).build();
        when(subscriptionRepository.findActiveSubscription(shopId)).thenReturn(Optional.of(sub));

        CustomerDemandEvent e1 = CustomerDemandEvent.builder()
                .eventType(DemandEventType.SEARCH)
                .queryText("Toor Dal")
                .normalizedQuery("toor dal")
                .latitude(BigDecimal.valueOf(12.9716))
                .longitude(BigDecimal.valueOf(77.5946))
                .createdAt(Instant.now())
                .build();

        CustomerDemandEvent e2 = CustomerDemandEvent.builder()
                .eventType(DemandEventType.SEARCH)
                .queryText("Toor Dal")
                .normalizedQuery("toor dal")
                .latitude(BigDecimal.valueOf(12.9716))
                .longitude(BigDecimal.valueOf(77.5946))
                .createdAt(Instant.now())
                .build();

        when(demandEventRepository.findEventsInBoundingBoxAndDateRange(any(), any(), any(), any(), any(), any()))
                .thenReturn(List.of(e1, e2))
                .thenReturn(List.of());

        when(shopProductOfferRepository.findByShopId(shopId)).thenReturn(List.of());
        when(nearbyShopRepository.findVerifiedShopsInBoundingBox(any(), any(), any(), any())).thenReturn(List.of());

        CustomerDemandDashboardResponse response = demandService.getShopDemandDashboard(
                shopId, DemandPeriod.LAST_7_DAYS, 5.0);

        assertThat(response.getOpportunities()).isNotEmpty();
        DemandOpportunityDto opp = response.getOpportunities().get(0);
        assertThat(opp.getType()).isEqualTo(OpportunityType.MISSING_PRODUCT);
        assertThat(opp.getProductName()).isEqualTo("Toor Dal");
        assertThat(opp.getSuggestedAction()).isEqualTo("Add to Catalog");
        assertThat(response.getMissingProductsCount()).isEqualTo(1);
    }

    @Test
    @DisplayName("Restock opportunity is identified when demanded item is OUT_OF_STOCK in shop catalog")
    void testRestockOpportunity_whenItemOutOfStock() {
        ShopSubscription sub = ShopSubscription.builder().shop(testShop).plan(paidPlan).build();
        when(subscriptionRepository.findActiveSubscription(shopId)).thenReturn(Optional.of(sub));

        CustomerDemandEvent e1 = CustomerDemandEvent.builder()
                .eventType(DemandEventType.SEARCH)
                .queryText("Sunflower Oil")
                .normalizedQuery("sunflower oil")
                .latitude(BigDecimal.valueOf(12.9716))
                .longitude(BigDecimal.valueOf(77.5946))
                .createdAt(Instant.now())
                .build();

        CustomerDemandEvent e2 = CustomerDemandEvent.builder()
                .eventType(DemandEventType.PRODUCT_VIEW)
                .queryText("Sunflower Oil")
                .normalizedQuery("sunflower oil")
                .latitude(BigDecimal.valueOf(12.9716))
                .longitude(BigDecimal.valueOf(77.5946))
                .createdAt(Instant.now())
                .build();

        ShopProductOffer offer = ShopProductOffer.builder()
                .shop(testShop)
                .rawProductName("Sunflower Oil 1L")
                .normalizedName("sunflower oil")
                .price(BigDecimal.valueOf(140.00))
                .availabilityStatus("OUT_OF_STOCK")
                .build();
        offer.setId(UUID.randomUUID());

        when(demandEventRepository.findEventsInBoundingBoxAndDateRange(any(), any(), any(), any(), any(), any()))
                .thenReturn(List.of(e1, e2))
                .thenReturn(List.of());

        when(shopProductOfferRepository.findByShopId(shopId)).thenReturn(List.of(offer));
        when(nearbyShopRepository.findVerifiedShopsInBoundingBox(any(), any(), any(), any())).thenReturn(List.of());

        CustomerDemandDashboardResponse response = demandService.getShopDemandDashboard(
                shopId, DemandPeriod.LAST_7_DAYS, 5.0);

        assertThat(response.getOpportunities()).isNotEmpty();
        DemandOpportunityDto opp = response.getOpportunities().get(0);
        assertThat(opp.getType()).isEqualTo(OpportunityType.OUT_OF_STOCK);
        assertThat(opp.getSuggestedAction()).isEqualTo("Restock Item");
        assertThat(response.getRestockOpportunitiesCount()).isEqualTo(1);
    }

    @Test
    @DisplayName("Free tier subscription gates full depth and caps visible products to 5")
    void testFreeTierGating() {
        ShopSubscription sub = ShopSubscription.builder().shop(testShop).plan(freePlan).build();
        when(subscriptionRepository.findActiveSubscription(shopId)).thenReturn(Optional.of(sub));

        List<CustomerDemandEvent> events = List.of(
                createEvent("Item 1"),
                createEvent("Item 2"),
                createEvent("Item 3"),
                createEvent("Item 4"),
                createEvent("Item 5"),
                createEvent("Item 6"),
                createEvent("Item 7")
        );

        when(demandEventRepository.findEventsInBoundingBoxAndDateRange(any(), any(), any(), any(), any(), any()))
                .thenReturn(events)
                .thenReturn(List.of());

        when(shopProductOfferRepository.findByShopId(shopId)).thenReturn(List.of());
        when(nearbyShopRepository.findVerifiedShopsInBoundingBox(any(), any(), any(), any())).thenReturn(List.of());

        CustomerDemandDashboardResponse response = demandService.getShopDemandDashboard(
                shopId, DemandPeriod.LAST_7_DAYS, 5.0);

        assertThat(response.isGated()).isTrue();
        assertThat(response.getSubscriptionTier()).isEqualTo("FREE");
        assertThat(response.getTopDemandedProducts()).hasSizeLessThanOrEqualTo(5);
        assertThat(response.getOpportunities()).hasSizeLessThanOrEqualTo(2);
    }

    @Test
    @DisplayName("Low data warning is flagged when unique signals fall below privacy threshold (< 3)")
    void testLowDataWarning() {
        ShopSubscription sub = ShopSubscription.builder().shop(testShop).plan(paidPlan).build();
        when(subscriptionRepository.findActiveSubscription(shopId)).thenReturn(Optional.of(sub));

        CustomerDemandEvent singleEvent = createEvent("Rare Organic Quinoa");

        when(demandEventRepository.findEventsInBoundingBoxAndDateRange(any(), any(), any(), any(), any(), any()))
                .thenReturn(List.of(singleEvent))
                .thenReturn(List.of());

        when(shopProductOfferRepository.findByShopId(shopId)).thenReturn(List.of());
        when(nearbyShopRepository.findVerifiedShopsInBoundingBox(any(), any(), any(), any())).thenReturn(List.of());

        CustomerDemandDashboardResponse response = demandService.getShopDemandDashboard(
                shopId, DemandPeriod.LAST_7_DAYS, 5.0);

        assertThat(response.getTopDemandedProducts()).hasSize(1);
        ProductDemandItemDto item = response.getTopDemandedProducts().get(0);
        assertThat(item.isLowDataWarning()).isTrue();
    }

    private CustomerDemandEvent createEvent(String name) {
        return CustomerDemandEvent.builder()
                .eventType(DemandEventType.SEARCH)
                .queryText(name)
                .normalizedQuery(name.toLowerCase())
                .latitude(BigDecimal.valueOf(12.9716))
                .longitude(BigDecimal.valueOf(77.5946))
                .createdAt(Instant.now())
                .build();
    }
}
