package com.homestock.modules.deals;

import com.homestock.modules.deals.entity.DealEntity;
import com.homestock.modules.deals.entity.DealPriceHistoryEntity;
import com.homestock.modules.deals.model.*;
import com.homestock.modules.deals.repository.DealPriceHistoryRepository;
import com.homestock.modules.deals.repository.DealRepository;
import com.homestock.modules.deals.service.DealFreshnessService;
import com.homestock.modules.deals.service.DealScoringEngine;
import com.homestock.modules.deals.service.DealValidationService;
import com.homestock.modules.deals.service.FinalPriceCalculationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@DisplayName("Deal Scoring, Validation and Freshness Engine Tests")
class DealScoringAndValidationEngineTest {

    private FinalPriceCalculationService priceCalculationService;
    private DealFreshnessService freshnessService;
    private DealScoringEngine scoringEngine;
    private DealValidationService validationService;
    private DealRepository dealRepository;
    private DealPriceHistoryRepository priceHistoryRepository;

    @BeforeEach
    void setUp() {
        priceCalculationService = new FinalPriceCalculationService();
        freshnessService = new DealFreshnessService();
        scoringEngine = new DealScoringEngine();
        dealRepository = mock(DealRepository.class);
        priceHistoryRepository = mock(DealPriceHistoryRepository.class);
        validationService = new DealValidationService(dealRepository, priceHistoryRepository, freshnessService);
    }

    @Test
    @DisplayName("Calculates Final Payable Price with delivery fee and discounts")
    void testFinalPriceCalculation() {
        DealCandidateInput candidate = DealCandidateInput.builder()
                .price(new BigDecimal("182.00"))
                .deliveryCharge(new BigDecimal("20.00"))
                .discount(new BigDecimal("10.00"))
                .couponDiscount(new BigDecimal("5.00"))
                .build();

        FinalPriceResult result = priceCalculationService.calculateFinalPrice(candidate);

        // 182 + 20 - 10 - 5 = 187
        assertEquals(0, new BigDecimal("187.00").compareTo(result.getFinalPrice()));
        assertEquals(1.0, result.getPriceConfidence());
        assertFalse(result.isDeliveryChargesMayApply());
    }

    @Test
    @DisplayName("Handles missing delivery fee with confidence penalty and disclosure")
    void testFinalPriceWithUnknownDelivery() {
        DealCandidateInput candidate = DealCandidateInput.builder()
                .price(new BigDecimal("189.00"))
                .deliveryCharge(null) // Unknown
                .build();

        FinalPriceResult result = priceCalculationService.calculateFinalPrice(candidate);

        assertEquals(0, new BigDecimal("189.00").compareTo(result.getFinalPrice()));
        assertTrue(result.isDeliveryChargesMayApply());
        assertTrue(result.getExplanation().contains("Delivery charges may apply"));
    }

    @Test
    @DisplayName("Enforces configurable TTL freshness rules across contexts")
    void testFreshnessTtl() {
        assertEquals(60, freshnessService.getTtlSeconds(DealFreshnessService.PriorityContext.ACTIVE_VIEW));
        assertEquals(180, freshnessService.getTtlSeconds(DealFreshnessService.PriorityContext.SHOPPING_LIST));
        assertEquals(600, freshnessService.getTtlSeconds(DealFreshnessService.PriorityContext.POPULAR));
        assertEquals(1800, freshnessService.getTtlSeconds(DealFreshnessService.PriorityContext.DEFAULT));

        Instant freshTime = Instant.now().minusSeconds(20);
        assertTrue(freshnessService.isFresh(freshTime, DealFreshnessService.PriorityContext.ACTIVE_VIEW));

        Instant staleTime = Instant.now().minusSeconds(120);
        assertFalse(freshnessService.isFresh(staleTime, DealFreshnessService.PriorityContext.ACTIVE_VIEW));
    }

    @Test
    @DisplayName("Detects price change and saves audit history record")
    void testPriceChangeDetectionAndHistory() {
        UUID existingDealId = UUID.randomUUID();
        DealEntity existingDeal = DealEntity.builder()
                .source(DealSource.FLIPKART)
                .externalProductId("FP-OIL-1")
                .price(new BigDecimal("182.00"))
                .finalPrice(new BigDecimal("182.00"))
                .build();
        existingDeal.setId(existingDealId);

        when(dealRepository.findBySourceAndExternalProductId(DealSource.FLIPKART, "FP-OIL-1"))
                .thenReturn(Optional.of(existingDeal));

        NormalizedProductQuery query = NormalizedProductQuery.builder()
                .canonicalQuantity(new BigDecimal("1000"))
                .canonicalUnit("ML")
                .build();

        DealCandidateInput updatedCandidate = DealCandidateInput.builder()
                .source(DealSource.FLIPKART)
                .externalProductId("FP-OIL-1")
                .title("Fortune Sunflower Oil 1L")
                .price(new BigDecimal("199.00")) // Price changed from 182 to 199
                .availability("IN_STOCK")
                .productUrl("https://www.flipkart.com/dp/FP-OIL-1")
                .build();

        ProductMatchResult match = ProductMatchResult.builder()
                .exactMatch(true)
                .matchScore(0.95)
                .category(DealMatchCategory.EXACT_MATCH)
                .signals(List.of(MatchSignal.builder().name("quantity").passed(true).build()))
                .build();

        FinalPriceResult finalPrice = FinalPriceResult.builder()
                .productPrice(new BigDecimal("199.00"))
                .finalPrice(new BigDecimal("199.00"))
                .deliveryCharge(BigDecimal.ZERO)
                .priceConfidence(1.0)
                .build();

        DealValidationService.ValidationResult result = validationService.validate(
                query, updatedCandidate, match, finalPrice, DealFreshnessService.PriorityContext.ACTIVE_VIEW);

        assertTrue(result.priceChanged());
        assertEquals(DealValidationStatus.PRICE_CHANGED, result.status());
        assertEquals(0, new BigDecimal("182.00").compareTo(result.oldPrice()));
        assertEquals(0, new BigDecimal("199.00").compareTo(result.currentPrice()));

        // Verify that history record was persisted
        ArgumentCaptor<DealPriceHistoryEntity> captor = ArgumentCaptor.forClass(DealPriceHistoryEntity.class);
        verify(priceHistoryRepository, times(1)).save(captor.capture());
        DealPriceHistoryEntity saved = captor.getValue();
        assertEquals(existingDealId, saved.getDealId());
        assertEquals(0, new BigDecimal("182.00").compareTo(saved.getOldPrice()));
        assertEquals(0, new BigDecimal("199.00").compareTo(saved.getNewPrice()));
    }

    @Test
    @DisplayName("Scores deal and assigns confidence tier (rejects below 70)")
    void testDealScoringAndConfidence() {
        ProductMatchResult highMatch = ProductMatchResult.builder()
                .matchScore(0.95)
                .exactMatch(true)
                .category(DealMatchCategory.EXACT_MATCH)
                .build();

        FinalPriceResult finalPrice = FinalPriceResult.builder()
                .productPrice(new BigDecimal("182.00"))
                .finalPrice(new BigDecimal("182.00"))
                .deliveryCharge(BigDecimal.ZERO)
                .priceConfidence(1.0)
                .build();

        DealScoringEngine.DealScoreResult highResult = scoringEngine.scoreDeal(
                highMatch, finalPrice, new BigDecimal("200.00"), Instant.now(), true, 4.5, true);

        assertTrue(highResult.confidenceScore() >= 85.0);
        assertTrue(highResult.confidenceLevel() == DealConfidenceLevel.HIGH || highResult.confidenceLevel() == DealConfidenceLevel.EXCELLENT);

        // Low confidence scenario
        ProductMatchResult lowMatch = ProductMatchResult.builder()
                .matchScore(0.30)
                .exactMatch(false)
                .category(DealMatchCategory.REJECTED)
                .build();

        DealScoringEngine.DealScoreResult lowResult = scoringEngine.scoreDeal(
                lowMatch, finalPrice, new BigDecimal("200.00"), Instant.now().minusSeconds(3600), false, 2.0, false);

        assertTrue(lowResult.confidenceScore() < 70.0, "Low match and out of stock should yield confidence < 70");
        assertEquals(DealConfidenceLevel.REJECTED, lowResult.confidenceLevel());
    }
}
