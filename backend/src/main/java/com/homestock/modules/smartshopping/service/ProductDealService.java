package com.homestock.modules.smartshopping.service;

import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.smartshopping.dto.*;
import com.homestock.modules.smartshopping.engine.*;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * ProductDealService:
 * Orchestrates the 6 smart shopping engines to provide real-world product deals,
 * price comparison across platforms, best value calculations, and dynamic filters.
 */
@Service
@RequiredArgsConstructor
public class ProductDealService {

    private static final Logger log = LoggerFactory.getLogger(ProductDealService.class);

    private final ProductIntentEngine intentEngine;
    private final ProductSearchEngine searchEngine;
    private final ProductMatchingEngine matchingEngine;
    private final ProductComparisonEngine comparisonEngine;
    private final DealRankingEngine rankingEngine;
    private final AIRecommendationEngine recommendationEngine;
    private final ShoppingListItemRepository listItemRepository;

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

        // 1. Understand Intent
        ProductSearchIntentDto intent = intentEngine.parseIntent(query, barcode, brand, unit);

        // 2. Search Providers
        List<ProductOfferDto> candidates = searchEngine.searchProviders(intent, 30);

        // 3. Match & Validate
        List<ProductOfferDto> matchedOffers = matchingEngine.filterAndScore(intent, candidates);

        // 4. Group & Compare Across Stores
        List<ProductDealDto> deals = comparisonEngine.groupAndCompareDeals(matchedOffers);

        // 5. Rank, Compute Unit Prices, Assign Badges & Dynamic Filters
        DealRankingEngine.RankedDealsResult rankedResult = rankingEngine.rankAndFilter(deals, intent, sortBy);

        // 6. Generate AI Recommendation & Highlights
        AIRecommendationEngine.AIRecommendationResult aiResult = recommendationEngine.generateSummaryAndHighlights(
                intent,
                rankedResult.deals(),
                rankedResult.lowestPriceDeal(),
                rankedResult.bestValueDeal(),
                rankedResult.popularDeal()
        );

        // 7. Apply In-Memory Filters (Subtype / Brand / Pack Size) if specified
        List<ProductDealDto> displayedDeals = rankedResult.deals();
        if (filterSubtype != null && !filterSubtype.isBlank()) {
            displayedDeals = displayedDeals.stream()
                    .filter(d -> d.getVariantType() != null && d.getVariantType().equalsIgnoreCase(filterSubtype.trim()))
                    .collect(Collectors.toList());
        }
        if (filterBrand != null && !filterBrand.isBlank()) {
            displayedDeals = displayedDeals.stream()
                    .filter(d -> d.getBrand() != null && d.getBrand().equalsIgnoreCase(filterBrand.trim()))
                    .collect(Collectors.toList());
        }
        if (filterPackSize != null && !filterPackSize.isBlank()) {
            displayedDeals = displayedDeals.stream()
                    .filter(d -> d.getPackageSize() != null && d.getPackageSize().equalsIgnoreCase(filterPackSize.trim()))
                    .collect(Collectors.toList());
        }

        return ProductDealSearchResponse.builder()
                .intent(intent)
                .summary(aiResult.summary())
                .highlights(aiResult.highlights())
                .products(displayedDeals)
                .filters(rankedResult.filters())
                .build();
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
}
