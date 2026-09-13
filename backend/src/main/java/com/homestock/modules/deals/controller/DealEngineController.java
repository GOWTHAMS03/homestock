package com.homestock.modules.deals.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.core.util.SecurityUtils;
import com.homestock.modules.deals.dto.*;
import com.homestock.modules.deals.entity.DealClickEvent;
import com.homestock.modules.deals.entity.DealEntity;
import com.homestock.modules.deals.entity.DealPriceHistoryEntity;
import com.homestock.modules.deals.entity.NearbyShop;
import com.homestock.modules.deals.model.DealValidationStatus;
import com.homestock.modules.deals.provider.LocalShopDealProvider;
import com.homestock.modules.deals.repository.DealClickEventRepository;
import com.homestock.modules.deals.repository.DealPriceHistoryRepository;
import com.homestock.modules.deals.repository.DealRepository;
import com.homestock.modules.deals.repository.NearbyShopRepository;
import com.homestock.modules.deals.service.*;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;

/**
 * Dedicated REST Controller for Real-Time & Location-Aware Smart Deals.
 */
@RestController
@RequestMapping({"/api/v1/deals", "/api/v1/api/v1/deals"})
@RequiredArgsConstructor
@Tag(name = "Deals Engine", description = "Real-time location-aware smart deals, nearby shops, and basket optimization")
public class DealEngineController {

    private final RealTimeDealEngine dealEngine;
    private final DealRepository dealRepository;
    private final DealPriceHistoryRepository priceHistoryRepository;
    private final ShoppingListItemRepository shoppingListItemRepository;
    private final com.homestock.modules.shopping.repository.ShoppingListRepository shoppingListRepository;
    private final com.homestock.core.security.HomeSecurityService homeSecurityService;
    private final RealTimeDealCacheService dealCacheService;

    // Location-Aware Deal Services
    private final LocalShopDealProvider localDealProvider;
    private final DealBasketOptimizer basketOptimizer;
    private final GeminiDealAiService geminiAiService;
    private final DealClickEventRepository clickEventRepository;
    private final NearbyShopRepository shopRepository;
    private final UserRepository userRepository;

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

    @GetMapping("/nearby")
    @Operation(summary = "Search location-aware deals across nearby physical shops and online providers")
    public ResponseEntity<ApiResponse<Map<String, Object>>> searchNearbyDeals(
            @RequestParam String q,
            @RequestParam(required = false) BigDecimal lat,
            @RequestParam(required = false) BigDecimal lon,
            @RequestParam(defaultValue = "5.0") Double radius,
            @RequestParam(required = false) UUID homeId,
            @RequestParam(required = false) UUID productId) {

        // Search local physical shops
        List<ShopDealDto> localDeals = localDealProvider.searchLocalDeals(q, lat, lon, radius, homeId, productId);

        // Search online adapters for comparison
        DealSearchResponseDto onlineResults = dealEngine.searchDeals(q, DealFreshnessService.PriorityContext.ACTIVE_VIEW);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("query", q);
        result.put("nearbyDeals", localDeals);
        result.put("onlineDeals", onlineResults != null ? onlineResults.getExactDeals() : Collections.emptyList());
        result.put("bestNearbyDeal", !localDeals.isEmpty() ? localDeals.get(0) : null);

        return ResponseEntity.ok(ApiResponse.success("Location-aware deals retrieved", result));
    }

    @PostMapping("/basket")
    @Operation(summary = "Optimize full shopping list basket across physical stores and online options")
    public ResponseEntity<ApiResponse<BasketOptimizationResponseDto>> optimizeBasket(
            @RequestBody BasketOptimizationRequestDto request) {

        BasketOptimizationResponseDto response = basketOptimizer.optimizeBasket(request);
        return ResponseEntity.ok(ApiResponse.success("Basket optimization completed", response));
    }

    @PostMapping("/voice-search")
    @Operation(summary = "Search deals using natural language / voice input (English, Tamil, Tanglish)")
    public ResponseEntity<ApiResponse<VoiceDealSearchResponseDto>> voiceSearchDeals(
            @RequestBody VoiceDealSearchRequestDto request) {

        GeminiDealAiService.ParsedDealIntent parsed = geminiAiService.parseShoppingQuery(request.getQuery());

        List<ShopDealDto> localDeals = Collections.emptyList();
        if (parsed.getProductName() != null && !parsed.getProductName().isBlank()) {
            localDeals = localDealProvider.searchLocalDeals(
                    parsed.getProductName(), request.getLatitude(), request.getLongitude(),
                    request.getRadiusKm(), null, null
            );
        }

        ShopDealDto bestDeal = !localDeals.isEmpty() ? localDeals.get(0) : null;
        List<ShopDealDto> otherDeals = localDeals.size() > 1 ? localDeals.subList(1, localDeals.size()) : Collections.emptyList();

        VoiceDealSearchResponseDto response = VoiceDealSearchResponseDto.builder()
                .transcript(request.getQuery())
                .detectedLanguage("MIXED")
                .intent(parsed.getIntent())
                .parsedProduct(parsed.getProductName())
                .parsedQuantity(parsed.getQuantity())
                .parsedUnit(parsed.getUnit())
                .conversationalReply(parsed.getConversationalReply())
                .bestNearbyDeal(bestDeal)
                .otherDeals(otherDeals)
                .build();

        return ResponseEntity.ok(ApiResponse.success("Voice deal search completed", response));
    }

    @PostMapping("/click")
    @Operation(summary = "Track deal click event and return direct external link")
    public ResponseEntity<ApiResponse<Map<String, String>>> trackDealClick(
            @RequestParam(required = false) UUID dealId,
            @RequestParam(required = false) UUID shopId,
            @RequestParam String provider,
            @RequestParam String targetUrl) {

        UUID userId = SecurityUtils.getCurrentUserId();
        User user = userRepository.findById(userId).orElse(null);

        if (user != null) {
            NearbyShop shop = shopId != null ? shopRepository.findById(shopId).orElse(null) : null;
            DealClickEvent event = DealClickEvent.builder()
                    .user(user)
                    .dealId(dealId)
                    .shop(shop)
                    .provider(provider)
                    .externalUrl(targetUrl)
                    .build();
            clickEventRepository.save(event);
        }

        return ResponseEntity.ok(ApiResponse.success("Deal click tracked", Map.of("targetUrl", targetUrl)));
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
