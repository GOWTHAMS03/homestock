package com.homestock.modules.deals.scheduler;

import com.homestock.modules.deals.adapter.DealSourceAdapter;
import com.homestock.modules.deals.adapter.DealSourceAdapterRegistry;
import com.homestock.modules.deals.entity.DealEntity;
import com.homestock.modules.deals.entity.DealPriceHistoryEntity;
import com.homestock.modules.deals.model.*;
import com.homestock.modules.deals.repository.DealPriceHistoryRepository;
import com.homestock.modules.deals.repository.DealRepository;
import com.homestock.modules.deals.service.DealFreshnessService;
import com.homestock.modules.deals.service.FinalPriceCalculationService;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;

/**
 * Background Deal Revalidation Scheduler (Phase 15).
 * Identifies STALE and expiring deals and revalidates them in priority order without hammering external sources.
 */
@Component
@RequiredArgsConstructor
public class DealRevalidationScheduler {

    private static final Logger log = LoggerFactory.getLogger(DealRevalidationScheduler.class);

    private final DealRepository dealRepository;
    private final DealPriceHistoryRepository priceHistoryRepository;
    private final DealSourceAdapterRegistry adapterRegistry;
    private final DealFreshnessService freshnessService;
    private final FinalPriceCalculationService priceCalculationService;

    @Value("${deals.scheduler.enabled:true}")
    private boolean enabled;

    @Value("${deals.scheduler.max-batch-size:10}")
    private int maxBatchSize = 10;

    @Scheduled(fixedDelayString = "${deals.scheduler.fixed-delay-ms:60000}", initialDelay = 30000)
    @Transactional
    public void revalidateStaleDeals() {
        if (!enabled) {
            return;
        }

        Instant now = Instant.now();
        List<DealEntity> staleDeals = dealRepository.findStaleDeals(now);
        if (staleDeals.isEmpty()) {
            return;
        }

        int count = Math.min(staleDeals.size(), maxBatchSize);
        log.info("[DealRevalidationScheduler] Found {} stale deals, revalidating top {}", staleDeals.size(), count);

        for (int i = 0; i < count; i++) {
            DealEntity deal = staleDeals.get(i);
            try {
                revalidateSingleDeal(deal);
            } catch (Exception e) {
                log.warn("[DealRevalidationScheduler] Failed to revalidate deal '{}': {}", deal.getProductName(), e.getMessage());
                deal.setValidationStatus(DealValidationStatus.STALE);
                dealRepository.save(deal);
            }
        }
    }

    private void revalidateSingleDeal(DealEntity deal) {
        Optional<DealSourceAdapter> adapterOpt = adapterRegistry.getAdapter(deal.getSource());
        if (adapterOpt.isEmpty() || !adapterOpt.get().isEnabled()) {
            // Cannot revalidate without adapter
            deal.setValidationStatus(DealValidationStatus.STALE);
            dealRepository.save(deal);
            return;
        }

        DealSourceAdapter adapter = adapterOpt.get();
        ExternalProduct product = ExternalProduct.builder()
                .source(deal.getSource())
                .externalProductId(deal.getExternalProductId())
                .title(deal.getProductName())
                .price(deal.getPrice())
                .productUrl(deal.getProductUrl())
                .build();

        // 1. Check current availability
        ProductAvailability avail = adapter.checkAvailability(product);
        if (!avail.isAvailable()) {
            deal.setValidationStatus(DealValidationStatus.OUT_OF_STOCK);
            deal.setStockStatus("OUT_OF_STOCK");
            deal.setLastVerifiedAt(Instant.now());
            dealRepository.save(deal);
            log.info("[DealRevalidationScheduler] Deal '{}' is now OUT_OF_STOCK", deal.getProductName());
            return;
        }

        // 2. Check current price
        PriceDetails currentPrice = adapter.getCurrentPrice(product);
        if (currentPrice.getPrice() == null || currentPrice.getPrice().compareTo(BigDecimal.ZERO) <= 0) {
            deal.setValidationStatus(DealValidationStatus.VALIDATION_FAILED);
            deal.setLastVerifiedAt(Instant.now());
            dealRepository.save(deal);
            return;
        }

        Instant now = Instant.now();
        BigDecimal oldPrice = deal.getPrice();
        BigDecimal newPrice = currentPrice.getPrice();

        if (oldPrice != null && oldPrice.compareTo(newPrice) != 0) {
            // Price changed!
            deal.setPrice(newPrice);
            deal.setValidationStatus(DealValidationStatus.PRICE_CHANGED);

            // Recompute final price
            DealCandidateInput cand = DealCandidateInput.builder()
                    .price(newPrice)
                    .deliveryCharge(currentPrice.getDeliveryCharge())
                    .discount(currentPrice.getDiscount())
                    .couponDiscount(currentPrice.getCouponDiscount())
                    .build();
            FinalPriceResult fp = priceCalculationService.calculateFinalPrice(cand);
            deal.setFinalPrice(fp.getFinalPrice());
            deal.setDeliveryCharge(fp.getDeliveryCharge());

            // Save price history record (Phase 8)
            DealPriceHistoryEntity history = DealPriceHistoryEntity.builder()
                    .dealId(deal.getId())
                    .oldPrice(oldPrice)
                    .newPrice(newPrice)
                    .source(deal.getSource())
                    .detectedAt(now)
                    .reason("Automated background revalidation detected price change")
                    .build();
            priceHistoryRepository.save(history);
            log.info("[DealRevalidationScheduler] Deal '{}' price changed from ₹{} to ₹{}", deal.getProductName(), oldPrice, newPrice);
        } else {
            deal.setValidationStatus(DealValidationStatus.VALID);
        }

        deal.setLastVerifiedAt(now);
        deal.setExpiresAt(freshnessService.calculateExpiration(DealFreshnessService.PriorityContext.DEFAULT));
        dealRepository.save(deal);
    }
}
