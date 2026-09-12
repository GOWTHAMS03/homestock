package com.homestock.modules.deals.service;

import com.homestock.modules.deals.adapter.DealSourceAdapterRegistry;
import com.homestock.modules.deals.dto.CanonicalDealDto;
import com.homestock.modules.deals.dto.DealSearchResponseDto;
import com.homestock.modules.deals.dto.StoreOfferDetailDto;
import com.homestock.modules.deals.entity.DealEntity;
import com.homestock.modules.deals.model.*;
import com.homestock.modules.deals.repository.DealRepository;
import com.homestock.modules.smartshopping.provider.ProductSearchRequest;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * RealTimeDealEngine:
 * Central engine orchestrating normalization, multi-adapter search, matching, validation,
 * final price calculation, deal scoring, canonical deduplication, and caching.
 * Core Principle: NO VALIDATION = NO DEAL.
 */
@Service
@RequiredArgsConstructor
public class RealTimeDealEngine {

    private static final Logger log = LoggerFactory.getLogger(RealTimeDealEngine.class);

    private final ProductQueryNormalizationService normalizationService;
    private final DealSourceAdapterRegistry adapterRegistry;
    private final ProductMatchingEngine matchingEngine;
    private final FinalPriceCalculationService priceCalculationService;
    private final DealValidationService validationService;
    private final DealScoringEngine scoringEngine;
    private final DealFreshnessService freshnessService;
    private final DealRepository dealRepository;

    // Fast in-memory cache for deal search responses (keyed by query + context)
    private final Map<String, CacheEntry> searchCache = new ConcurrentHashMap<>();
    private record CacheEntry(DealSearchResponseDto response, Instant expiresAt) {}

    /**
     * Search validated real-world deals for a user query.
     */
    @Transactional
    public DealSearchResponseDto searchDeals(String query, DealFreshnessService.PriorityContext priorityContext) {
        long startTime = System.currentTimeMillis();
        NormalizedProductQuery normalized = normalizationService.normalize(query);

        String cacheKey = "deal:search:" + normalized.getNormalizedQuery().toLowerCase().trim();
        CacheEntry cached = searchCache.get(cacheKey);
        if (cached != null && Instant.now().isBefore(cached.expiresAt())) {
            log.debug("[RealTimeDealEngine] Cache HIT for '{}'", normalized.getNormalizedQuery());
            return cached.response();
        }

        // 1. Build provider search request
        ProductSearchRequest searchReq = ProductSearchRequest.builder()
                .itemName(normalized.getProduct() != null ? normalized.getProduct() : normalized.getNormalizedQuery())
                .brand(normalized.getBrand())
                .quantity(normalized.getCanonicalQuantity())
                .unit(normalized.getCanonicalUnit())
                .maxResults(25)
                .build();

        // 2. Dispatch parallel search across adapters
        List<ExternalProduct> rawCandidates = adapterRegistry.searchAll(searchReq);
        log.info("[RealTimeDealEngine] Retrieved {} raw candidates for query '{}'",
                rawCandidates.size(), normalized.getNormalizedQuery());

        // 3. Process each candidate through Matching, Final Price, Validation, and Scoring
        List<ValidatedCandidate> validatedList = new ArrayList<>();
        BigDecimal highestPrice = BigDecimal.ZERO;

        for (ExternalProduct ext : rawCandidates) {
            DealCandidateInput candidate = toCandidateInput(ext, normalized);
            if (candidate.getPrice() != null && candidate.getPrice().compareTo(highestPrice) > 0) {
                highestPrice = candidate.getPrice();
            }

            // Matching Engine (Phase 3 & 4)
            ProductMatchResult matchResult = matchingEngine.match(normalized, candidate);

            // Final Price Calculation (Phase 9)
            FinalPriceResult finalPrice = priceCalculationService.calculateFinalPrice(candidate);

            // Strict Validation Pipeline (Phase 6 & 12)
            DealValidationService.ValidationResult valResult = validationService.validate(
                    normalized, candidate, matchResult, finalPrice, priorityContext);

            // "NO VALIDATION = NO DEAL": Reject invalid deals from Best Deals
            if (!valResult.isEligibleBestDeal()) {
                log.debug("[NO_VALIDATION_NO_DEAL] Excluded candidate '{}' from {}: {}",
                        candidate.getTitle(), candidate.getSource(), valResult.failureReason());
                continue;
            }

            Instant now = Instant.now();
            boolean inStock = !"OUT_OF_STOCK".equalsIgnoreCase(candidate.getAvailability());
            boolean urlVerified = candidate.getProductUrl() != null && !candidate.getProductUrl().isBlank();

            // Deal Scoring & Confidence (Phase 10 & 11)
            DealScoringEngine.DealScoreResult scoreResult = scoringEngine.scoreDeal(
                    matchResult, finalPrice, highestPrice, now, inStock, candidate.getSellerRating(), urlVerified);

            // Reject deals below 70 confidence (Phase 11)
            if (scoreResult.confidenceScore() < 70.0) {
                log.debug("[LOW_CONFIDENCE_REJECT] Excluded deal '{}' (Confidence: {})",
                        candidate.getTitle(), scoreResult.confidenceScore());
                continue;
            }

            // Save / Update in DB (Phase 14)
            DealEntity dealEntity = persistDeal(candidate, finalPrice, matchResult, valResult.status(), scoreResult, now, priorityContext);

            validatedList.add(new ValidatedCandidate(candidate, matchResult, finalPrice, scoreResult, valResult.status(), dealEntity, now));
        }

        // 4. Canonical Product Deduplication (Phase 18)
        List<CanonicalDealDto> exactDeals = deduplicateAndGroup(validatedList.stream()
                .filter(v -> v.matchResult.getCategory() == DealMatchCategory.EXACT_MATCH)
                .collect(Collectors.toList()));

        List<CanonicalDealDto> alternativeDeals = deduplicateAndGroup(validatedList.stream()
                .filter(v -> v.matchResult.getCategory() == DealMatchCategory.SIMILAR_ALTERNATIVE)
                .collect(Collectors.toList()));

        Instant now = Instant.now();
        Instant expiresAt = freshnessService.calculateExpiration(priorityContext);

        String message;
        if (!exactDeals.isEmpty()) {
            message = "Found " + exactDeals.size() + " verified exact deal" + (exactDeals.size() > 1 ? "s" : "");
        } else if (!alternativeDeals.isEmpty()) {
            message = "Exact product unavailable. Showing " + alternativeDeals.size() + " validated alternative" + (alternativeDeals.size() > 1 ? "s" : "");
        } else {
            message = "No verified deals found matching your requirements.";
        }

        DealSearchResponseDto response = DealSearchResponseDto.builder()
                .query(query)
                .normalizedQuery(normalized)
                .exactDeals(exactDeals)
                .alternativeDeals(alternativeDeals)
                .searchedAt(now)
                .expiresAt(expiresAt)
                .message(message)
                .totalFound(exactDeals.size() + alternativeDeals.size())
                .build();

        // Cache response with TTL (Phase 13)
        searchCache.put(cacheKey, new CacheEntry(response, expiresAt));
        log.info("[RealTimeDealEngine] Completed in {}ms: {} exact deals, {} alternative deals",
                (System.currentTimeMillis() - startTime), exactDeals.size(), alternativeDeals.size());

        return response;
    }

    /**
     * Deduplicates multi-store offers under one canonical product card (Phase 18).
     */
    private List<CanonicalDealDto> deduplicateAndGroup(List<ValidatedCandidate> list) {
        if (list == null || list.isEmpty()) return Collections.emptyList();

        // Group by canonical key: brand + product + variant + quantity + unit + packCount
        Map<String, List<ValidatedCandidate>> grouped = new LinkedHashMap<>();
        for (ValidatedCandidate v : list) {
            String key = buildCanonicalKey(v.candidate);
            grouped.computeIfAbsent(key, k -> new ArrayList<>()).add(v);
        }

        List<CanonicalDealDto> canonicalDeals = new ArrayList<>();
        for (Map.Entry<String, List<ValidatedCandidate>> entry : grouped.entrySet()) {
            List<ValidatedCandidate> offers = entry.getValue();
            // Sort offers by final price ascending (cheapest first)
            offers.sort(Comparator.comparing(o -> o.finalPrice.getFinalPrice()));

            ValidatedCandidate best = offers.get(0);
            List<StoreOfferDetailDto> otherStores = new ArrayList<>();

            for (ValidatedCandidate o : offers) {
                boolean isBest = o == best;
                otherStores.add(StoreOfferDetailDto.builder()
                        .storeName(o.candidate.getSource() != null ? o.candidate.getSource().getDisplayName() : "Store")
                        .source(o.candidate.getSource())
                        .price(o.candidate.getPrice())
                        .mrp(o.candidate.getMrp())
                        .deliveryCharge(o.finalPrice.getDeliveryCharge())
                        .finalPrice(o.finalPrice.getFinalPrice())
                        .availability(o.candidate.getAvailability())
                        .deliveryStatus(o.candidate.getDeliveryStatus())
                        .productUrl(o.candidate.getProductUrl())
                        .affiliateUrl(o.candidate.getAffiliateUrl())
                        .validationStatus(o.status)
                        .lastVerifiedAt(o.verifiedAt)
                        .freshnessLabel(freshnessService.formatFreshnessLabel(o.verifiedAt))
                        .isBestPrice(isBest)
                        .build());
            }

            CanonicalDealDto canonical = CanonicalDealDto.builder()
                    .canonicalId(entry.getKey())
                    .productName(best.candidate.getTitle())
                    .brand(best.candidate.getBrand())
                    .variant(best.candidate.getVariant())
                    .packageSize(formatPackageSize(best.candidate.getQuantity(), best.candidate.getUnit()))
                    .quantity(best.candidate.getQuantity())
                    .unit(best.candidate.getUnit())
                    .packCount(best.candidate.getPackCount())
                    .bestPrice(best.candidate.getPrice())
                    .bestFinalPrice(best.finalPrice.getFinalPrice())
                    .bestSource(best.candidate.getSource())
                    .bestProductUrl(best.candidate.getProductUrl())
                    .bestAffiliateUrl(best.candidate.getAffiliateUrl())
                    .imageUrl(best.candidate.getImageUrl())
                    .exactMatch(best.matchResult.isExactMatch())
                    .matchScore(best.matchResult.getMatchScore())
                    .confidenceScore(best.scoreResult.confidenceScore())
                    .confidenceLevel(best.scoreResult.confidenceLevel())
                    .validationStatus(best.status)
                    .lastVerifiedAt(best.verifiedAt)
                    .freshnessLabel(freshnessService.formatFreshnessLabel(best.verifiedAt))
                    .category(best.candidate.getCategory())
                    .sellerName(best.candidate.getSellerName())
                    .otherStores(otherStores)
                    .signals(best.matchResult.getSignals())
                    .build();

            canonicalDeals.add(canonical);
        }

        // Sort canonical deals: exact matches first, then lowest final price
        canonicalDeals.sort(Comparator.comparing(CanonicalDealDto::isExactMatch).reversed()
                .thenComparing(CanonicalDealDto::getBestFinalPrice));

        return canonicalDeals;
    }

    private String buildCanonicalKey(DealCandidateInput c) {
        String b = c.getBrand() != null ? c.getBrand().trim().toLowerCase() : "generic";
        String v = c.getVariant() != null ? c.getVariant().trim().toLowerCase() : "";
        String q = c.getQuantity() != null ? c.getQuantity().stripTrailingZeros().toPlainString() : "1";
        String u = c.getUnit() != null ? c.getUnit().trim().toLowerCase() : "";
        int p = c.getPackCount() != null ? c.getPackCount() : 1;
        return b + ":" + v + ":" + q + u + ":" + p;
    }

    private String formatPackageSize(BigDecimal qty, String unit) {
        if (qty == null) return null;
        return qty.stripTrailingZeros().toPlainString() + (unit != null ? " " + unit : "");
    }

    private DealCandidateInput toCandidateInput(ExternalProduct ext, NormalizedProductQuery normalized) {
        BigDecimal qty = ext.getQuantity() != null ? ext.getQuantity() : normalized.getCanonicalQuantity();
        String unit = ext.getUnit() != null ? ext.getUnit() : normalized.getCanonicalUnit();
        int pack = ext.getPackCount() != null ? ext.getPackCount() : 1;

        return DealCandidateInput.builder()
                .source(ext.getSource())
                .externalProductId(ext.getExternalProductId() != null ? ext.getExternalProductId() : UUID.randomUUID().toString())
                .title(ext.getTitle())
                .brand(ext.getBrand() != null ? ext.getBrand() : normalized.getBrand())
                .category(ext.getCategory() != null ? ext.getCategory() : normalized.getCategory())
                .variant(ext.getVariant() != null ? ext.getVariant() : normalized.getVariant())
                .quantity(qty)
                .unit(unit)
                .packCount(pack)
                .price(ext.getPrice())
                .mrp(ext.getMrp())
                .deliveryCharge(ext.getDeliveryCharge())
                .discount(ext.getDiscount())
                .currency(ext.getCurrency() != null ? ext.getCurrency() : "INR")
                .availability(ext.getAvailability() != null ? ext.getAvailability() : "IN_STOCK")
                .deliveryStatus(ext.getDeliveryStatus())
                .sellerName(ext.getSellerName())
                .productUrl(ext.getProductUrl())
                .affiliateUrl(ext.getAffiliateUrl())
                .imageUrl(ext.getImageUrl())
                .sellerRating(ext.getRating())
                .confidence(0.95)
                .build();
    }

    private DealEntity persistDeal(
            DealCandidateInput candidate,
            FinalPriceResult finalPrice,
            ProductMatchResult matchResult,
            DealValidationStatus status,
            DealScoringEngine.DealScoreResult scoreResult,
            Instant now,
            DealFreshnessService.PriorityContext priorityContext
    ) {
        Optional<DealEntity> existing = dealRepository.findBySourceAndExternalProductId(
                candidate.getSource(), candidate.getExternalProductId());

        Instant expiresAt = freshnessService.calculateExpiration(priorityContext);
        DealEntity entity = existing.orElseGet(DealEntity::new);

        entity.setSource(candidate.getSource());
        entity.setExternalProductId(candidate.getExternalProductId());
        entity.setCanonicalProductId(buildCanonicalKey(candidate));
        entity.setProductName(candidate.getTitle());
        entity.setBrand(candidate.getBrand());
        entity.setVariant(candidate.getVariant());
        entity.setQuantity(candidate.getQuantity());
        entity.setUnit(candidate.getUnit());
        entity.setPackCount(candidate.getPackCount());
        entity.setPrice(candidate.getPrice());
        entity.setDeliveryCharge(finalPrice.getDeliveryCharge());
        entity.setDiscount(finalPrice.getDiscount());
        entity.setCouponDiscount(finalPrice.getCouponDiscount());
        entity.setFinalPrice(finalPrice.getFinalPrice());
        entity.setCurrency(candidate.getCurrency());
        entity.setStockStatus(candidate.getAvailability());
        entity.setDeliveryStatus(candidate.getDeliveryStatus());
        entity.setSellerName(candidate.getSellerName());
        entity.setProductUrl(candidate.getProductUrl());
        entity.setAffiliateUrl(candidate.getAffiliateUrl());
        entity.setImageUrl(candidate.getImageUrl());
        entity.setMatchScore(matchResult.getMatchScore());
        entity.setConfidenceScore(scoreResult.confidenceScore());
        entity.setValidationStatus(status);
        entity.setLastVerifiedAt(now);
        entity.setExpiresAt(expiresAt);

        return dealRepository.save(entity);
    }

    private record ValidatedCandidate(
            DealCandidateInput candidate,
            ProductMatchResult matchResult,
            FinalPriceResult finalPrice,
            DealScoringEngine.DealScoreResult scoreResult,
            DealValidationStatus status,
            DealEntity entity,
            Instant verifiedAt
    ) {}
}
