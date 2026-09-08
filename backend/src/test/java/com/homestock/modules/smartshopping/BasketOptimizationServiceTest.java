package com.homestock.modules.smartshopping;

import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.smartshopping.dto.BasketOptionDto;
import com.homestock.modules.smartshopping.dto.ProductOfferDto;
import com.homestock.modules.smartshopping.service.BasketOptimizationService;
import com.homestock.modules.smartshopping.service.OfferRankingService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;

class BasketOptimizationServiceTest {

    private BasketOptimizationService basketService;

    @BeforeEach
    void setUp() {
        OfferRankingService rankingService = new OfferRankingService();
        basketService = new BasketOptimizationService(rankingService);
    }

    @Test
    @DisplayName("Compute Option A (split) vs Option B (single-store) with delivery threshold awareness")
    void computeBasketOptions() {
        UUID item1Id = UUID.randomUUID();
        UUID item2Id = UUID.randomUUID();

        ShoppingListItem item1 = ShoppingListItem.builder()
                .itemName("India Gate Basmati Rice")
                .quantity(new BigDecimal("1"))
                .unit("kg")
                .build();

        ShoppingListItem item2 = ShoppingListItem.builder()
                .itemName("Fortune Sunflower Oil")
                .quantity(new BigDecimal("1"))
                .unit("L")
                .build();

        Map<UUID, ShoppingListItem> itemMap = Map.of(item1Id, item1, item2Id, item2);

        // For item 1: Amazon ₹120, Flipkart ₹150
        ProductOfferDto amzRice = ProductOfferDto.builder()
                .provider("Amazon")
                .providerProductId("B001")
                .productName("India Gate Basmati Rice 1kg")
                .price(new BigDecimal("120.00"))
                .deliveryCharge(BigDecimal.ZERO)
                .effectivePrice(new BigDecimal("120.00"))
                .lastCheckedAt(Instant.now())
                .matchConfidence(0.95)
                .matchType("EXACT")
                .build();

        ProductOfferDto flipRice = ProductOfferDto.builder()
                .provider("Flipkart")
                .providerProductId("F001")
                .productName("India Gate Basmati Rice 1kg")
                .price(new BigDecimal("150.00"))
                .deliveryCharge(BigDecimal.ZERO)
                .effectivePrice(new BigDecimal("150.00"))
                .lastCheckedAt(Instant.now())
                .matchConfidence(0.95)
                .matchType("EXACT")
                .build();

        // For item 2: Amazon ₹210, Flipkart ₹180
        ProductOfferDto amzOil = ProductOfferDto.builder()
                .provider("Amazon")
                .providerProductId("B002")
                .productName("Fortune Sunflower Oil 1L")
                .price(new BigDecimal("210.00"))
                .deliveryCharge(BigDecimal.ZERO)
                .effectivePrice(new BigDecimal("210.00"))
                .lastCheckedAt(Instant.now())
                .matchConfidence(0.95)
                .matchType("EXACT")
                .build();

        ProductOfferDto flipOil = ProductOfferDto.builder()
                .provider("Flipkart")
                .providerProductId("F002")
                .productName("Fortune Sunflower Oil 1L")
                .price(new BigDecimal("180.00"))
                .deliveryCharge(BigDecimal.ZERO)
                .effectivePrice(new BigDecimal("180.00"))
                .lastCheckedAt(Instant.now())
                .matchConfidence(0.95)
                .matchType("EXACT")
                .build();

        Map<UUID, List<ProductOfferDto>> offers = new HashMap<>();
        offers.put(item1Id, List.of(amzRice, flipRice));
        offers.put(item2Id, List.of(amzOil, flipOil));

        List<BasketOptionDto> options = basketService.computeBasketOptions(offers, itemMap, null);

        assertThat(options).hasSize(2);

        BasketOptionDto optA = options.stream()
                .filter(o -> "OPTION_A_INDIVIDUAL_BEST".equals(o.getOptionType()))
                .findFirst().orElseThrow();

        BasketOptionDto optB = options.stream()
                .filter(o -> "OPTION_B_SINGLE_STORE".equals(o.getOptionType()))
                .findFirst().orElseThrow();

        // Option A picks Amazon for Rice (₹120) and Flipkart for Oil (₹180) -> subtotal = ₹300
        assertThat(optA.getItemsSubtotal()).isEqualByComparingTo(new BigDecimal("300.00"));
        // Both stores are below free delivery threshold (Amazon 499, Flipkart 500), so delivery fees apply to both
        assertThat(optA.getDeliveryFeesTotal()).isGreaterThan(BigDecimal.ZERO);

        // Option B picks a single store (Amazon subtotal 330, Flipkart subtotal 330)
        assertThat(optB.getItems()).hasSize(2);
        assertThat(optB.getRecommendationReason()).isNotNull();
    }
}
