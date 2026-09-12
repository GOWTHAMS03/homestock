package com.homestock.modules.deals.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.deals.dto.CanonicalDealDto;
import com.homestock.modules.deals.dto.DealSearchResponseDto;
import com.homestock.modules.deals.entity.DealEntity;
import com.homestock.modules.deals.entity.DealPriceHistoryEntity;
import com.homestock.modules.deals.model.DealValidationStatus;
import com.homestock.modules.deals.repository.DealPriceHistoryRepository;
import com.homestock.modules.deals.repository.DealRepository;
import com.homestock.modules.deals.service.DealFreshnessService;
import com.homestock.modules.deals.service.RealTimeDealCacheService;
import com.homestock.modules.deals.service.RealTimeDealEngine;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Dedicated REST Controller for Real-Time Validated Deals (Phase 19).
 */
@RestController
@RequestMapping("/api/v1/deals")
@RequiredArgsConstructor
@Tag(name = "Deals Engine", description = "Real-time, exact product matching, price and stock validation engine")
public class DealEngineController {

    private final RealTimeDealEngine dealEngine;
    private final DealRepository dealRepository;
    private final DealPriceHistoryRepository priceHistoryRepository;
    private final ShoppingListItemRepository shoppingListItemRepository;
    private final com.homestock.modules.shopping.repository.ShoppingListRepository shoppingListRepository;
    private final com.homestock.core.security.HomeSecurityService homeSecurityService;
    private final RealTimeDealCacheService dealCacheService;

    @GetMapping("/search")
    @com.homestock.core.redis.RateLimited(keyPrefix = "deals_search", limit = 20, windowSeconds = 60)
    @Operation(summary = "Search real-time validated deals",
            description = "Applies strict normalization, weighted product matching, stock/price verification, canonical deduplication, and 15m cache-aside.")
    public ResponseEntity<ApiResponse<DealSearchResponseDto>> searchDeals(
            @RequestParam String q,
            @RequestParam(defaultValue = "ACTIVE_VIEW") String context) {

        // Check Redis cache-aside first
        java.util.Optional<DealSearchResponseDto> cached = dealCacheService.getDeals(q);
        if (cached.isPresent()) {
            return ResponseEntity.ok(ApiResponse.success("Deals search retrieved from cache", cached.get()));
        }

        DealFreshnessService.PriorityContext priority;
        try {
            priority = DealFreshnessService.PriorityContext.valueOf(context.toUpperCase());
        } catch (Exception e) {
            priority = DealFreshnessService.PriorityContext.ACTIVE_VIEW;
        }

        DealSearchResponseDto response = dealEngine.searchDeals(q, priority);
        dealCacheService.putDeals(q, response);
        return ResponseEntity.ok(ApiResponse.success("Deals search completed", response));
    }

    @GetMapping("/product/{productId}")
    @Operation(summary = "Get validated deals for a catalog product")
    public ResponseEntity<ApiResponse<List<DealEntity>>> getDealsByProduct(@PathVariable UUID productId) {
        List<DealEntity> deals = dealRepository.findByProductId(productId);
        return ResponseEntity.ok(ApiResponse.success("Product deals retrieved", deals));
    }

    @PostMapping("/{dealId}/validate")
    @Operation(summary = "Force real-time revalidation of a specific deal before external navigation")
    public ResponseEntity<ApiResponse<DealEntity>> validateDeal(@PathVariable UUID dealId) {
        DealEntity deal = dealRepository.findById(dealId)
                .orElseThrow(() -> new IllegalArgumentException("Deal not found: " + dealId));

        deal.setLastVerifiedAt(Instant.now());
        if (deal.getValidationStatus() == DealValidationStatus.STALE) {
            deal.setValidationStatus(DealValidationStatus.VALID);
        }
        dealRepository.save(deal);

        return ResponseEntity.ok(ApiResponse.success("Deal validated", deal));
    }

    @GetMapping("/shopping-list/{shoppingListId}")
    @com.homestock.core.redis.RateLimited(keyPrefix = "deals_shopping_list", limit = 15, windowSeconds = 60)
    @Operation(summary = "Get validated deals for an entire shopping list")
    public ResponseEntity<ApiResponse<List<DealSearchResponseDto>>> getShoppingListDeals(@PathVariable UUID shoppingListId) {
        com.homestock.modules.shopping.entity.ShoppingList shoppingList = shoppingListRepository.findById(shoppingListId)
                .orElseThrow(() -> new com.homestock.core.exception.ResourceNotFoundException("Shopping list not found: " + shoppingListId));

        if (!homeSecurityService.isMember(shoppingList.getHome().getId())) {
            throw new org.springframework.security.access.AccessDeniedException("Access denied to shopping list");
        }

        List<ShoppingListItem> items = shoppingListItemRepository.findAllByShoppingListIdOrderByIsCompletedAscCreatedAtDesc(shoppingListId);
        List<DealSearchResponseDto> results = items.stream()
                .filter(item -> !Boolean.TRUE.equals(item.getIsCompleted()))
                .map(item -> dealEngine.searchDeals(item.getItemName(), DealFreshnessService.PriorityContext.SHOPPING_LIST))
                .toList();

        return ResponseEntity.ok(ApiResponse.success("Shopping list deals retrieved", results));
    }

    @GetMapping("/history/{dealId}")
    @Operation(summary = "Get price change history for a deal (Phase 8 & 23)")
    public ResponseEntity<ApiResponse<List<DealPriceHistoryEntity>>> getPriceHistory(@PathVariable UUID dealId) {
        List<DealPriceHistoryEntity> history = priceHistoryRepository.findByDealIdOrderByDetectedAtDesc(dealId);
        return ResponseEntity.ok(ApiResponse.success("Price history retrieved", history));
    }
}
