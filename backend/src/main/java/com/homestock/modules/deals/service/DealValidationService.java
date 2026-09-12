package com.homestock.modules.deals.service;

import com.homestock.modules.deals.entity.DealEntity;
import com.homestock.modules.deals.entity.DealPriceHistoryEntity;
import com.homestock.modules.deals.model.*;
import com.homestock.modules.deals.repository.DealPriceHistoryRepository;
import com.homestock.modules.deals.repository.DealRepository;
import com.homestock.modules.smartshopping.engine.url.ProductUrlValidator;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;

/**
 * Deal Validation Service (Phases 6, 8, & 12).
 * Strictly enforces "NO VALIDATION = NO DEAL" pipeline, tracks price changes, and persists audit history.
 */
@Service
@RequiredArgsConstructor
public class DealValidationService {

    private static final Logger log = LoggerFactory.getLogger(DealValidationService.class);

    private final DealRepository dealRepository;
    private final DealPriceHistoryRepository priceHistoryRepository;
    private final DealFreshnessService freshnessService;
    private final ProductUrlValidator urlValidator = new ProductUrlValidator();

    public record ValidationResult(
            DealValidationStatus status,
            boolean isEligibleBestDeal,
            boolean priceChanged,
            BigDecimal oldPrice,
            BigDecimal currentPrice,
            String failureReason
    ) {}

    /**
     * Executes the strict 8-step validation pipeline.
     */
    @Transactional
    public ValidationResult validate(
            NormalizedProductQuery requested,
            DealCandidateInput candidate,
            ProductMatchResult matchResult,
            FinalPriceResult finalPrice,
            DealFreshnessService.PriorityContext priorityContext
    ) {
        if (candidate == null) {
            return new ValidationResult(DealValidationStatus.VALIDATION_FAILED, false, false, null, null, "Candidate is null");
        }

        // 1. Product Match & Category
        if (matchResult == null || !matchResult.isAcceptable()) {
            return new ValidationResult(DealValidationStatus.VALIDATION_FAILED, false, false, null, candidate.getPrice(),
                    matchResult != null ? matchResult.getReason() : "Matching failed");
        }

        // 2. Quantity Validation (Rule: Wrong quantity cannot be exact match)
        if (matchResult.getCategory() == DealMatchCategory.EXACT_MATCH && requested.getCanonicalQuantity() != null) {
            boolean qtyPassed = matchResult.getSignals().stream()
                    .anyMatch(s -> "quantity".equals(s.getName()) && s.isPassed());
            if (!qtyPassed) {
                return new ValidationResult(DealValidationStatus.QUANTITY_MISMATCH, false, false, null, candidate.getPrice(),
                        "Quantity mismatch against user request");
            }
        }

        // 3. Variant Validation
        if (requested.getVariant() != null) {
            boolean variantPassed = matchResult.getSignals().stream()
                    .anyMatch(s -> "variant".equals(s.getName()) && s.isPassed());
            if (!variantPassed && matchResult.getCategory() == DealMatchCategory.EXACT_MATCH) {
                return new ValidationResult(DealValidationStatus.VARIANT_MISMATCH, false, false, null, candidate.getPrice(),
                        "Variant mismatch: " + candidate.getVariant());
            }
        }

        // 4. Price Valid
        if (candidate.getPrice() == null || candidate.getPrice().compareTo(BigDecimal.ZERO) <= 0) {
            return new ValidationResult(DealValidationStatus.VALIDATION_FAILED, false, false, null, candidate.getPrice(),
                    "Invalid or zero price");
        }

        // 5. Stock Valid
        if (candidate.getAvailability() != null) {
            String avail = candidate.getAvailability().toUpperCase();
            if (avail.contains("OUT_OF_STOCK") || avail.contains("UNAVAILABLE")) {
                return new ValidationResult(DealValidationStatus.OUT_OF_STOCK, false, false, null, candidate.getPrice(),
                        "Product is currently out of stock");
            }
        }

        // 6. URL Valid (No broken or generic URLs without provider reference)
        if (candidate.getProductUrl() == null || candidate.getProductUrl().isBlank()
                || !candidate.getProductUrl().startsWith("http")) {
            return new ValidationResult(DealValidationStatus.INVALID_URL, false, false, null, candidate.getPrice(),
                    "Invalid or missing product URL");
        }

        // 7. Price Change Detection (Phase 8)
        boolean priceChanged = false;
        BigDecimal oldPrice = null;
        if (candidate.getSource() != null && candidate.getExternalProductId() != null) {
            Optional<DealEntity> existingDealOpt = dealRepository.findBySourceAndExternalProductId(
                    candidate.getSource(), candidate.getExternalProductId());

            if (existingDealOpt.isPresent()) {
                DealEntity existing = existingDealOpt.get();
                oldPrice = existing.getPrice();
                if (oldPrice != null && oldPrice.compareTo(candidate.getPrice()) != 0) {
                    priceChanged = true;
                    log.info("[PRICE_CHANGED] Deal '{}' on {} changed from ₹{} to ₹{}",
                            candidate.getTitle(), candidate.getSource(), oldPrice, candidate.getPrice());

                    // Record price history
                    DealPriceHistoryEntity history = DealPriceHistoryEntity.builder()
                            .dealId(existing.getId())
                            .oldPrice(oldPrice)
                            .newPrice(candidate.getPrice())
                            .source(candidate.getSource())
                            .detectedAt(Instant.now())
                            .reason(String.format("Price updated from ₹%.2f to ₹%.2f during search validation",
                                    oldPrice.doubleValue(), candidate.getPrice().doubleValue()))
                            .build();
                    priceHistoryRepository.save(history);
                }
            }
        }

        // 8. Determine Status
        DealValidationStatus status = priceChanged ? DealValidationStatus.PRICE_CHANGED : DealValidationStatus.VALID;

        // Best Deals eligibility: Must be VALID or PRICE_CHANGED and have confidence
        boolean isEligible = status.isEligibleForBestDeals();

        return new ValidationResult(status, isEligible, priceChanged, oldPrice, candidate.getPrice(), null);
    }
}
