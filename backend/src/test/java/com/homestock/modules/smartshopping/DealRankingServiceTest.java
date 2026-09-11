package com.homestock.modules.smartshopping;

import com.homestock.modules.smartshopping.dto.ProductDealDto;
import com.homestock.modules.smartshopping.dto.ProductIntent;
import com.homestock.modules.smartshopping.dto.SearchIntent;
import com.homestock.modules.smartshopping.service.UnitNormalizationService;
import com.homestock.modules.smartshopping.service.ranking.DealRankingService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class DealRankingServiceTest {

    private DealRankingService rankingService;

    @BeforeEach
    void setUp() {
        rankingService = new DealRankingService(new UnitNormalizationService());
    }

    @Test
    @DisplayName("Requirement 16: Effective price logic - Product B with free delivery (₹155) beats Product A with delivery (₹145 + ₹40 = ₹185)")
    void testEffectivePriceRanking() {
        ProductIntent intent = ProductIntent.builder()
                .productName("Fortune Sunflower Oil 1L")
                .brand("Fortune")
                .packSize("1L")
                .quantity(BigDecimal.ONE)
                .searchIntent(SearchIntent.EXACT_PRODUCT)
                .build();

        ProductDealDto productA = ProductDealDto.builder()
                .productName("Fortune Sunflower Oil 1L (Store A)")
                .brand("Fortune")
                .packageSize("1 L")
                .unit("L")
                .bestPrice(new BigDecimal("145"))
                .deliveryCharge(new BigDecimal("40")) // Effective = ₹185
                .matchScore(98.0)
                .build();

        ProductDealDto productB = ProductDealDto.builder()
                .productName("Fortune Sunflower Oil 1L (Store B)")
                .brand("Fortune")
                .packageSize("1 L")
                .unit("L")
                .bestPrice(new BigDecimal("155"))
                .deliveryCharge(BigDecimal.ZERO) // Effective = ₹155
                .matchScore(98.0)
                .build();

        var container = rankingService.rankAndSegregate(List.of(productA, productB), intent, "lowest_price");

        assertFalse(container.primaryDeals().isEmpty());
        // Lowest effective price must be product B (₹155)
        ProductDealDto topDeal = container.primaryDeals().get(0);
        assertEquals(new BigDecimal("155"), topDeal.getEffectivePrice());
        assertEquals("Fortune Sunflower Oil 1L (Store B)", topDeal.getProductName());
    }

    @Test
    @DisplayName("Requirement 4: Required quantity cost calculation: ₹150 for 1L with user quantity 3 -> requiredTotal = ₹450")
    void testRequiredQuantityTotalCalculation() {
        ProductIntent intent = ProductIntent.builder()
                .productName("Fortune Sunflower Oil 1L")
                .brand("Fortune")
                .packSize("1L")
                .quantity(new BigDecimal("3")) // 3 bottles required
                .searchIntent(SearchIntent.EXACT_PRODUCT)
                .build();

        ProductDealDto deal = ProductDealDto.builder()
                .productName("Fortune Sunflower Oil 1L")
                .brand("Fortune")
                .packageSize("1 L")
                .unit("L")
                .bestPrice(new BigDecimal("150"))
                .deliveryCharge(BigDecimal.ZERO)
                .matchScore(98.0)
                .build();

        var container = rankingService.rankAndSegregate(List.of(deal), intent, "default");

        ProductDealDto processedDeal = container.primaryDeals().get(0);
        assertEquals(new BigDecimal("150.00"), processedDeal.getUnitPrice());
        assertEquals(new BigDecimal("450.00"), processedDeal.getRequiredQuantityCost());
    }

    @Test
    @DisplayName("Requirement 8 & 15: Exact match segregated from similar products - Ariel never appears in exact deals for Surf Excel")
    void testBrandSegregationInRanking() {
        ProductIntent intent = ProductIntent.builder()
                .productName("Surf Excel Matic 2kg")
                .brand("Surf Excel")
                .packSize("2kg")
                .quantity(BigDecimal.ONE)
                .searchIntent(SearchIntent.EXACT_PRODUCT)
                .build();

        ProductDealDto exactSurf = ProductDealDto.builder()
                .productName("Surf Excel Matic Detergent 2kg")
                .brand("Surf Excel")
                .packageSize("2 kg")
                .bestPrice(new BigDecimal("320"))
                .matchScore(96.0)
                .build();

        ProductDealDto similarAriel = ProductDealDto.builder()
                .productName("Ariel Matic Detergent 2kg")
                .brand("Ariel")
                .packageSize("2 kg")
                .bestPrice(new BigDecimal("290"))
                .matchScore(65.0)
                .build();

        var container = rankingService.rankAndSegregate(List.of(exactSurf, similarAriel), intent, "default");

        assertEquals(1, container.exactDeals().size());
        assertEquals("Surf Excel", container.exactDeals().get(0).getBrand());
        assertEquals(1, container.similarDeals().size());
        assertEquals("Ariel", container.similarDeals().get(0).getBrand());
    }
}
