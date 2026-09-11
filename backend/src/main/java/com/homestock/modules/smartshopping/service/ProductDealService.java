package com.homestock.modules.smartshopping.service;

import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.smartshopping.dto.*;
import com.homestock.modules.smartshopping.engine.AIRecommendationEngine;
import com.homestock.modules.smartshopping.engine.DealRankingEngine;
import com.homestock.modules.smartshopping.engine.ProductComparisonEngine;
import com.homestock.modules.smartshopping.engine.ProductIntentEngine;
import com.homestock.modules.smartshopping.engine.ProductMatchingEngine;
import com.homestock.modules.smartshopping.engine.ProductSearchEngine;
import com.homestock.modules.smartshopping.engine.intent.ProductIntentExtractor;
import com.homestock.modules.smartshopping.engine.intent.ProductNormalizer;
import com.homestock.modules.smartshopping.engine.intent.SearchIntentClassifier;
import com.homestock.modules.smartshopping.engine.intent.SearchQueryBuilder;
import com.homestock.modules.smartshopping.engine.matching.ProductMatchEngine;
import com.homestock.modules.smartshopping.provider.ShoppingProviderRegistry;
import com.homestock.modules.smartshopping.service.anomaly.PriceAnomalyDetector;
import com.homestock.modules.smartshopping.service.cache.DealCacheService;
import com.homestock.modules.smartshopping.service.dedup.ProductDeduplicationService;
import com.homestock.modules.smartshopping.service.ranking.DealRankingService;
import com.homestock.modules.smartshopping.service.search.MultiEngineSearchService;
import com.homestock.modules.smartshopping.service.verification.ImageVerificationService;
import com.homestock.modules.smartshopping.service.verification.PriceVerificationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

/**
 * ProductDealService:
 * Central orchestrator for product deal discovery across the 6 search engines.
 * Coordinates 12 modular components:
 * 1. ProductIntentExtractor
 * 2. ProductNormalizer
 * 3. SearchIntentClassifier
 * 4. SearchQueryBuilder
 * 5. MultiEngineSearchService (6 search providers)
 * 6. ProductMatchEngine (Point-based scoring & Brand Protection)
 * 7. ProductDeduplicationService (Canonical fingerprinting)
 * 8. PriceVerificationService
 * 9. ImageVerificationService
 * 10. DealRankingService (Effective price, unit price, quantity cost, Deal Score)
 * 11. PriceAnomalyDetector
 * 12. DealCacheService (TTL caching)
 */
@Service
public class ProductDealService {

    private static final Logger log = LoggerFactory.getLogger(ProductDealService.class);

    private final ProductIntentExtractor intentExtractor;
    private final ProductNormalizer normalizer;
    private final SearchIntentClassifier intentClassifier;
    private final SearchQueryBuilder queryBuilder;
    private final MultiEngineSearchService multiEngineSearchService;
    private final ProductMatchEngine matchEngine;
    private final ProductDeduplicationService dedupService;
    private final PriceVerificationService priceVerificationService;
    private final ImageVerificationService imageVerificationService;
    private final DealRankingService dealRankingService;
    private final PriceAnomalyDetector anomalyDetector;
    private final DealCacheService cacheService;

    // Legacy engines & repository preserved for backward compatibility
    private final ProductIntentEngine legacyIntentEngine;
    private final AIRecommendationEngine recommendationEngine;
    private final ShoppingListItemRepository listItemRepository;

    /**
     * Primary constructor used by Spring Boot dependency injection.
     */
    @Autowired
    public ProductDealService(
            ProductIntentExtractor intentExtractor,
            ProductNormalizer normalizer,
            SearchIntentClassifier intentClassifier,
            SearchQueryBuilder queryBuilder,
            MultiEngineSearchService multiEngineSearchService,
            ProductMatchEngine matchEngine,
            ProductDeduplicationService dedupService,
            PriceVerificationService priceVerificationService,
            ImageVerificationService imageVerificationService,
            DealRankingService dealRankingService,
            PriceAnomalyDetector anomalyDetector,
            DealCacheService cacheService,
            ProductIntentEngine legacyIntentEngine,
            AIRecommendationEngine recommendationEngine,
            ShoppingListItemRepository listItemRepository
    ) {
        this.intentExtractor = intentExtractor;
        this.normalizer = normalizer;
        this.intentClassifier = intentClassifier;
        this.queryBuilder = queryBuilder;
        this.multiEngineSearchService = multiEngineSearchService;
        this.matchEngine = matchEngine;
        this.dedupService = dedupService;
        this.priceVerificationService = priceVerificationService;
        this.imageVerificationService = imageVerificationService;
        this.dealRankingService = dealRankingService;
        this.anomalyDetector = anomalyDetector;
        this.cacheService = cacheService;
        this.legacyIntentEngine = legacyIntentEngine;
        this.recommendationEngine = recommendationEngine;
        this.listItemRepository = listItemRepository;
    }

    /**
     * Backward-compatible constructor for existing tests.
     */
    public ProductDealService(
            ProductIntentEngine intentEngine,
            ProductSearchEngine searchEngine,
            ProductMatchingEngine matchingEngine,
            ProductComparisonEngine comparisonEngine,
            DealRankingEngine rankingEngine,
            AIRecommendationEngine recommendationEngine,
            ShoppingListItemRepository listItemRepository
    ) {
        this.normalizer = new ProductNormalizer();
        this.intentClassifier = new SearchIntentClassifier();
        this.intentExtractor = new ProductIntentExtractor(this.normalizer, this.intentClassifier);
        this.queryBuilder = new SearchQueryBuilder();

        // Reflection to retrieve providerRegistry from searchEngine if available
        ShoppingProviderRegistry registry = null;
        try {
            java.lang.reflect.Field field = ProductSearchEngine.class.getDeclaredField("providerRegistry");
            field.setAccessible(true);
            registry = (ShoppingProviderRegistry) field.get(searchEngine);
        } catch (Exception ignored) {}

        if (registry == null) {
            registry = new ShoppingProviderRegistry(Collections.emptyList());
        }

        this.multiEngineSearchService = new MultiEngineSearchService(registry, this.queryBuilder);
        this.matchEngine = new ProductMatchEngine();
        this.dedupService = new ProductDeduplicationService();
        this.priceVerificationService = new PriceVerificationService();
        this.imageVerificationService = new ImageVerificationService();
        this.dealRankingService = new DealRankingService(new UnitNormalizationService());
        this.anomalyDetector = new PriceAnomalyDetector();
        this.cacheService = new DealCacheService();
        this.legacyIntentEngine = intentEngine;
        this.recommendationEngine = recommendationEngine;
        this.listItemRepository = listItemRepository;
    }

    /**
     * Search deals for a text query with optional filters and sorting.
     */
    @Transactional(readOnly = true)
    public ProductDealSearchResponse searchDeals(
            UUID homeId,
            String query,
            String barcode,
            String brand,
            String unit,
            String filterSubtype,
            String filterBrand,
            String filterPackSize,
            String sortBy
    ) {
        log.info("[ProductDealService] HomeId={}, Query='{}', Barcode='{}', Brand='{}', SubtypeFilter='{}', SortBy='{}'",
                homeId, query, barcode, brand, filterSubtype, sortBy);

        String cacheKey = (homeId != null ? homeId.toString() : "global") + ":" +
                (query != null ? query.trim() : "") + ":" +
                (barcode != null ? barcode.trim() : "") + ":" +
                (brand != null ? brand.trim() : "") + ":" +
                (filterSubtype != null ? filterSubtype.trim() : "") + ":" +
                (filterBrand != null ? filterBrand.trim() : "") + ":" +
                (filterPackSize != null ? filterPackSize.trim() : "") + ":" +
                (sortBy != null ? sortBy.trim() : "default");

        Optional<ProductDealSearchResponse> cached = cacheService.get(cacheKey);
        if (cached.isPresent()) {
            return cached.get();
        }

        // 1. Build Structured Product Intent (18+ fields, quantity vs pack size separated)
        ProductIntent productIntent = intentExtractor.extractIntent(query, barcode, brand, unit);
        ProductSearchIntentDto legacyIntent = legacyIntentEngine.parseIntent(query, barcode, brand, unit);

        // 2. Ambiguous query check
        if (productIntent.getSearchIntent() == SearchIntent.INSUFFICIENT_INFORMATION) {
            log.info("[ProductDealService] Query '{}' classified as INSUFFICIENT_INFORMATION", query);
        }

        // 3. Dispatch parallel search across the 6 enabled search engines with timeouts & fallback
        List<ProductCandidate> candidates = multiEngineSearchService.searchAllEngines(productIntent, 30);

        // 4. Verify prices, images, anomalies, and calculate Product Match Scores
        List<ProductCandidate> scoredCandidates = new ArrayList<>();
        for (ProductCandidate candidate : candidates) {
            // Strict 0% Mock Guarantee: reject any mock or demo candidates
            if (candidate.getProvider() != null &&
                    (candidate.getProvider().toUpperCase().contains("MOCK") ||
                     candidate.getProvider().toUpperCase().contains("DEMO"))) {
                continue;
            }

            priceVerificationService.verifyPrice(candidate);
            imageVerificationService.verifyImage(candidate);
            anomalyDetector.inspect(candidate);

            ProductMatchEngine.ScoredCandidate scored = matchEngine.match(productIntent, candidate);
            candidate.setMatchScore(scored.score());
            candidate.setMatchStatus(scored.status());

            // Exclude rejected matches (< 70) from deals consideration
            if (scored.score() >= 70.0 && !scored.isBrandClash()) {
                scoredCandidates.add(candidate);
            } else if (!scored.isBrandClash() && scored.score() >= 50.0) {
                // Keep for similar products pool
                scoredCandidates.add(candidate);
            }
        }

        // 5. Deduplicate candidates using canonical fingerprint (BRAND|NAME|VARIANT|PACK_SIZE|BARCODE)
        List<ProductDealDto> rawDeals = dedupService.deduplicateAndGroup(scoredCandidates);

        // 6. Rank deals, compute effective price (price + delivery), unit price, quantity total, and segregate exact vs similar
        DealRankingService.RankedDealsContainer ranked = dealRankingService.rankAndSegregate(rawDeals, productIntent, sortBy);

        // 7. Apply In-Memory Filters (Subtype / Brand / Pack Size) if specified
        List<ProductDealDto> displayedDeals = applyFilters(ranked.primaryDeals(), filterSubtype, filterBrand, filterPackSize);
        List<ProductDealDto> exactDeals = applyFilters(ranked.exactDeals(), filterSubtype, filterBrand, filterPackSize);
        List<ProductDealDto> similarDeals = applyFilters(ranked.similarDeals(), filterSubtype, filterBrand, filterPackSize);

        // 8. Determine Overall Match Status
        MatchStatus matchStatus;
        String message = null;

        if (productIntent.getSearchIntent() == SearchIntent.INSUFFICIENT_INFORMATION && displayedDeals.isEmpty()) {
            matchStatus = MatchStatus.AMBIGUOUS;
            message = "Term is ambiguous. Please specify a brand or variant for exact deal matching.";
        } else if (!exactDeals.isEmpty()) {
            double topScore = exactDeals.get(0).getMatchScore() != null ? exactDeals.get(0).getMatchScore() : 90.0;
            matchStatus = topScore >= 95.0 ? MatchStatus.VERIFIED_EXACT : MatchStatus.HIGH_CONFIDENCE;
            if (productIntent.getSearchIntent() == SearchIntent.GENERIC_PRODUCT) {
                message = "Best deals for " + (productIntent.getGenericName() != null ? productIntent.getGenericName() : query);
            } else {
                message = "Exact match found";
            }
        } else if (!similarDeals.isEmpty()) {
            matchStatus = MatchStatus.POSSIBLE_MATCH;
            message = "Exact product unavailable. Showing similar products.";
        } else {
            matchStatus = MatchStatus.NOT_FOUND;
            message = "Exact product could not be verified.";
        }

        // 9. Generate AI Recommendation & Highlights
        AIRecommendationEngine.AIRecommendationResult aiResult = recommendationEngine.generateSummaryAndHighlights(
                legacyIntent,
                displayedDeals,
                ranked.lowestPriceDeal(),
                ranked.bestValueDeal(),
                ranked.popularDeal()
        );

        // 10. Build Shopping Item Intent Summary
        ShoppingItemIntentDto shoppingItem = ShoppingItemIntentDto.builder()
                .name(productIntent.getProductName())
                .brand(productIntent.getBrand())
                .requiredQuantity(productIntent.getQuantity())
                .unit(productIntent.getUnit())
                .packSize(productIntent.getPackSize())
                .build();

        // 11. Construct Response
        ProductDealSearchResponse response = ProductDealSearchResponse.builder()
                .shoppingItem(shoppingItem)
                .searchIntent(productIntent.getSearchIntent())
                .matchStatus(matchStatus)
                .deals(displayedDeals)
                .products(displayedDeals) // backward compatibility
                .exactDeals(exactDeals)
                .similarDeals(similarDeals)
                .productIntent(productIntent)
                .intent(legacyIntent)
                .summary(aiResult.summary())
                .highlights(aiResult.highlights())
                .filters(ranked.filters())
                .message(message)
                .build();

        // 12. Cache Result
        cacheService.put(cacheKey, response);

        return response;
    }

    /**
     * Search deals directly for a Shopping List item.
     */
    @Transactional(readOnly = true)
    public ProductDealSearchResponse searchDealsForShoppingListItem(UUID homeId, UUID listItemId, String sortBy) {
        ShoppingListItem item = listItemRepository.findById(listItemId)
                .orElseThrow(() -> new ResourceNotFoundException("Shopping list item not found: " + listItemId));

        String brand = null;
        if (item.getProduct() != null && item.getProduct().getBrand() != null) {
            brand = item.getProduct().getBrand();
        }

        String unit = item.getUnit();
        String barcode = item.getBarcode();
        String query = item.getItemName();

        // If package size can be inferred from quantity and unit
        if (item.getQuantity() != null && unit != null && !unit.isBlank()) {
            query = query + " " + item.getQuantity().stripTrailingZeros().toPlainString() + " " + unit;
        }

        return searchDeals(homeId, query, barcode, brand, unit, null, null, null, sortBy);
    }

    private List<ProductDealDto> applyFilters(
            List<ProductDealDto> list,
            String filterSubtype,
            String filterBrand,
            String filterPackSize
    ) {
        if (list == null || list.isEmpty()) return Collections.emptyList();
        List<ProductDealDto> filtered = new ArrayList<>(list);

        if (filterSubtype != null && !filterSubtype.isBlank()) {
            filtered = filtered.stream()
                    .filter(d -> d.getVariantType() != null && d.getVariantType().equalsIgnoreCase(filterSubtype.trim()))
                    .collect(Collectors.toList());
        }
        if (filterBrand != null && !filterBrand.isBlank()) {
            filtered = filtered.stream()
                    .filter(d -> d.getBrand() != null && d.getBrand().equalsIgnoreCase(filterBrand.trim()))
                    .collect(Collectors.toList());
        }
        if (filterPackSize != null && !filterPackSize.isBlank()) {
            filtered = filtered.stream()
                    .filter(d -> {
                        String s = d.getPackageSize() != null ? d.getPackageSize() : d.getPackSize();
                        return s != null && s.equalsIgnoreCase(filterPackSize.trim());
                    })
                    .collect(Collectors.toList());
        }

        return filtered;
    }
}
