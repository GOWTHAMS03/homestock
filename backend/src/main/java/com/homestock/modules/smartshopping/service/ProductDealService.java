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
import com.homestock.modules.smartshopping.engine.clustering.CanonicalProductClusterer;
import com.homestock.modules.smartshopping.engine.filter.HardConstraintFilter;
import com.homestock.modules.smartshopping.engine.identity.BrandResolver;
import com.homestock.modules.smartshopping.engine.identity.ProductAttributeExtractor;
import com.homestock.modules.smartshopping.engine.identity.ProductIdentityResolver;
import com.homestock.modules.smartshopping.engine.identity.ProductTaxonomy;
import com.homestock.modules.smartshopping.engine.intent.ProductIntentExtractor;
import com.homestock.modules.smartshopping.engine.intent.ProductNormalizer;
import com.homestock.modules.smartshopping.engine.intent.SearchIntentClassifier;
import com.homestock.modules.smartshopping.engine.intent.SearchQueryBuilder;
import com.homestock.modules.smartshopping.engine.matching.EvidenceScorer;
import com.homestock.modules.smartshopping.engine.matching.FuzzySimilarityEngine;
import com.homestock.modules.smartshopping.engine.matching.ProductIdentityMatcher;
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
 * Redesigned around PRODUCT IDENTITY RESOLUTION:
 * 1. ProductIdentityResolver (Canonical Identity & Hard Constraints)
 * 2. SearchQueryBuilder & QueryPlan (5-level progressive relaxation)
 * 3. MultiEngineSearchService (6 search providers, parallel dispatch, 0% mock guarantee)
 * 4. HardConstraintFilter & ProductIdentityMatcher (Hard pre-filter, multi-signal evidence, rejection tracing)
 * 5. CanonicalProductClusterer (Multi-seller grouping, price verification, anomaly detection, effective quantity cost)
 * 6. DealCacheService (TTL caching)
 */
@Service
public class ProductDealService {

    private static final Logger log = LoggerFactory.getLogger(ProductDealService.class);

    private final ProductIdentityResolver identityResolver;
    private final ProductIdentityMatcher identityMatcher;
    private final CanonicalProductClusterer clusterer;
    private final SearchQueryBuilder queryBuilder;
    private final MultiEngineSearchService multiEngineSearchService;
    private final DealCacheService cacheService;

    // Legacy engines & repository preserved for backward compatibility
    private final ProductIntentExtractor intentExtractor;
    private final ProductNormalizer normalizer;
    private final SearchIntentClassifier intentClassifier;
    private final ProductMatchEngine matchEngine;
    private final ProductDeduplicationService dedupService;
    private final PriceVerificationService priceVerificationService;
    private final ImageVerificationService imageVerificationService;
    private final DealRankingService dealRankingService;
    private final PriceAnomalyDetector anomalyDetector;
    private final ProductIntentEngine legacyIntentEngine;
    private final AIRecommendationEngine recommendationEngine;
    private final ShoppingListItemRepository listItemRepository;

    /**
     * Primary constructor used by Spring Boot dependency injection.
     */
    @Autowired
    public ProductDealService(
            ProductIdentityResolver identityResolver,
            ProductIdentityMatcher identityMatcher,
            CanonicalProductClusterer clusterer,
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
        this.identityResolver = identityResolver;
        this.identityMatcher = identityMatcher;
        this.clusterer = clusterer;
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
        FuzzySimilarityEngine fuzzyEngine = new FuzzySimilarityEngine();
        BrandResolver brandResolver = new BrandResolver(fuzzyEngine);
        ProductTaxonomy taxonomy = new ProductTaxonomy();
        ProductAttributeExtractor attributeExtractor = new ProductAttributeExtractor(brandResolver, taxonomy);

        this.identityResolver = new ProductIdentityResolver(attributeExtractor);
        HardConstraintFilter filter = new HardConstraintFilter(brandResolver, attributeExtractor, taxonomy);
        EvidenceScorer scorer = new EvidenceScorer(fuzzyEngine, brandResolver, attributeExtractor);
        this.identityMatcher = new ProductIdentityMatcher(filter, scorer);
        this.clusterer = new CanonicalProductClusterer();

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

        // 1. Resolve Canonical Product Identity & Hard Identity Constraints
        ProductIdentity identity = identityResolver.resolve(query, barcode);

        // If brand was explicitly passed as parameter and not extracted, overlay it
        if (identity.getBrand() == null && brand != null && !brand.isBlank()) {
            identity.setBrand(brand.trim());
        }

        // Backward compatibility intent
        ProductIntent productIntent = intentExtractor.extractIntent(query, barcode, brand, unit);
        ProductSearchIntentDto legacyIntent = legacyIntentEngine.parseIntent(query, barcode, brand, unit);

        // 2. Build 5-level progressive QueryPlan
        QueryPlan queryPlan = queryBuilder.buildQueryPlan(identity, query);

        // 3. Dispatch parallel search across the 6 enabled search engines with timeouts & fallback
        List<ProductCandidate> rawCandidates = multiEngineSearchService.searchAllEngines(identity, queryPlan, 30);

        // 4. Hard Constraint Pre-Filtering + Multi-Signal Evidence Scoring + Rejection Tracing
        ProductIdentityMatcher.MatchResult matchResult = identityMatcher.matchCandidates(identity, rawCandidates);
        List<ProductCandidate> validCandidates = matchResult.getValidCandidates();
        List<RejectedCandidate> rejectedCandidates = matchResult.getRejectedCandidates();

        // 5. Cluster candidates into canonical products, verify prices, and isolate similar products
        CanonicalProductClusterer.ClusteringResult clusteringResult = clusterer.clusterAndRank(identity, validCandidates);
        List<ProductDealDto> primaryDeals = clusteringResult.getPrimaryDeals();
        List<ProductDealDto> similarProducts = clusteringResult.getSimilarProducts();

        // 6. Apply In-Memory Filters (Subtype / Brand / Pack Size) if specified
        List<ProductDealDto> filteredPrimaryDeals = applyFilters(primaryDeals, filterSubtype, filterBrand, filterPackSize);
        List<ProductDealDto> filteredSimilarProducts = applyFilters(similarProducts, filterSubtype, filterBrand, filterPackSize);

        // 7. Determine Overall Match Status and Message
        MatchStatus matchStatus;
        String message;

        if (identity.getSearchMode() == SearchIntent.INSUFFICIENT_INFORMATION && filteredPrimaryDeals.isEmpty()) {
            matchStatus = MatchStatus.AMBIGUOUS;
            message = "Term is ambiguous. Please specify a brand or variant for exact deal matching.";
        } else if (!filteredPrimaryDeals.isEmpty()) {
            double topConfidence = filteredPrimaryDeals.get(0).getIdentityConfidence() != null
                    ? filteredPrimaryDeals.get(0).getIdentityConfidence()
                    : 0.9;
            matchStatus = topConfidence >= 0.90 ? MatchStatus.VERIFIED_EXACT : MatchStatus.HIGH_CONFIDENCE;
            if (identity.getSearchMode() == SearchIntent.GENERIC_PRODUCT || identity.getSearchMode() == SearchIntent.GENERIC_SEARCH) {
                message = "Best deals for " + (identity.getProduct() != null ? identity.getProduct() : query);
            } else {
                message = "Exact match found";
            }
        } else if (!filteredSimilarProducts.isEmpty()) {
            matchStatus = MatchStatus.POSSIBLE_MATCH;
            message = "Exact product unavailable. Showing similar products.";
        } else {
            matchStatus = MatchStatus.NOT_FOUND;
            message = "Exact product could not be verified.";
        }

        // 8. Generate SearchDebugTrace
        SearchDebugTrace debugTrace = SearchDebugTrace.builder()
                .rawInput(query)
                .resolvedIdentity(identity)
                .generatedQueries(queryPlan.getActiveQueries())
                .rawEngineCandidatesCount(rawCandidates.size())
                .rejectedCandidates(rejectedCandidates)
                .validCandidatesCount(validCandidates.size())
                .clustersCount(clusteringResult.getTotalClustersCount())
                .build();

        // 9. Rank deals and compute summary & filter facets
        DealRankingService.RankedDealsContainer ranked = dealRankingService.rankAndSegregate(
                filteredPrimaryDeals, productIntent, sortBy);

        AIRecommendationEngine.AIRecommendationResult aiResult = recommendationEngine.generateSummaryAndHighlights(
                legacyIntent,
                filteredPrimaryDeals,
                ranked.lowestPriceDeal(),
                ranked.bestValueDeal(),
                ranked.popularDeal()
        );

        // 10. Build Shopping Item Intent Summary
        String packSizeStr = identity.getPackSize() != null
                ? identity.getPackSize().stripTrailingZeros().toPlainString() + (identity.getPackUnit() != null ? identity.getPackUnit() : "")
                : null;

        ShoppingItemIntentDto shoppingItem = ShoppingItemIntentDto.builder()
                .name(identity.getProduct())
                .brand(identity.getBrand())
                .requiredQuantity(identity.getRequestedQuantity() != null ? identity.getRequestedQuantity() : BigDecimal.ONE)
                .unit(identity.getRequestedQuantityUnit())
                .packSize(packSizeStr)
                .build();

        // 11. Construct Response
        ProductDealSearchResponse response = ProductDealSearchResponse.builder()
                .query(query)
                .productIdentity(identity)
                .confidence(identity.getConfidence())
                .shoppingItem(shoppingItem)
                .searchIntent(productIntent.getSearchIntent())
                .matchStatus(matchStatus)
                .deals(filteredPrimaryDeals)
                .products(filteredPrimaryDeals) // backward compatibility
                .exactDeals(filteredPrimaryDeals)
                .similarDeals(filteredSimilarProducts)
                .similarProducts(filteredSimilarProducts)
                .debugTrace(debugTrace)
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
