package com.homestock.modules.smartshopping.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.core.util.SecurityUtils;
import com.homestock.modules.purchase.dto.PurchaseDto;
import com.homestock.modules.smartshopping.dto.*;
import com.homestock.modules.smartshopping.entity.PriceHistory;
import com.homestock.modules.smartshopping.entity.ShoppingSession;
import com.homestock.modules.smartshopping.provider.ShoppingProviderRegistry;
import com.homestock.modules.smartshopping.repository.PriceHistoryRepository;
import com.homestock.modules.smartshopping.service.PriceComparisonService;
import com.homestock.modules.smartshopping.service.ProductDealService;
import com.homestock.modules.smartshopping.service.ShoppingSessionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/homes/{homeId}")
@RequiredArgsConstructor
@Tag(name = "Smart Shopping", description = "Price comparison, multi-provider basket optimization, and shopping session endpoints")
public class SmartShoppingController {

    private final PriceComparisonService priceComparisonService;
    private final ProductDealService productDealService;
    private final ShoppingSessionService shoppingSessionService;
    private final ShoppingProviderRegistry providerRegistry;
    private final PriceHistoryRepository priceHistoryRepository;

    @GetMapping("/shopping-list/items/{itemId}/offers")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get price comparison for a single shopping item",
            description = "Searches all enabled providers for matching products, applies product matching, and returns ranked offers.")
    public ResponseEntity<ApiResponse<PriceComparisonResponse>> getItemOffers(
            @PathVariable UUID homeId,
            @PathVariable UUID itemId) {

        PriceComparisonResponse comparison = priceComparisonService.compareItem(homeId, itemId);
        return ResponseEntity.ok(ApiResponse.success("Price comparison completed", comparison));
    }

    @GetMapping("/shopping/deals/search")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Search real-world product deals",
            description = "Analyzes query intent (generic discovery vs exact), compares cross-store prices, computes unit values, and returns ranked deals.")
    public ResponseEntity<ApiResponse<ProductDealSearchResponse>> searchDeals(
            @PathVariable UUID homeId,
            @RequestParam(required = false) String query,
            @RequestParam(required = false) String barcode,
            @RequestParam(required = false) String brand,
            @RequestParam(required = false) String unit,
            @RequestParam(required = false) String subtype,
            @RequestParam(required = false) String filterBrand,
            @RequestParam(required = false) String filterPackSize,
            @RequestParam(defaultValue = "default") String sortBy) {

        ProductDealSearchResponse response = productDealService.searchDeals(
                homeId, query, barcode, brand, unit, subtype, filterBrand, filterPackSize, sortBy);
        return ResponseEntity.ok(ApiResponse.success("Deals search completed", response));
    }

    @GetMapping("/shopping-list/items/{itemId}/deals")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Find real-world deals for a shopping list item",
            description = "Extracts intent and parameters from the shopping list item and returns live cross-store deals.")
    public ResponseEntity<ApiResponse<ProductDealSearchResponse>> getItemDeals(
            @PathVariable UUID homeId,
            @PathVariable UUID itemId,
            @RequestParam(defaultValue = "default") String sortBy) {

        ProductDealSearchResponse response = productDealService.searchDealsForShoppingListItem(homeId, itemId, sortBy);
        return ResponseEntity.ok(ApiResponse.success("Item deals retrieved", response));
    }

    @PostMapping("/shopping/compare/basket")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Compare multi-item shopping basket",
            description = "Computes Option A (split across lowest prices) vs Option B (single-store convenience), along with duplicate warnings.")
    public ResponseEntity<ApiResponse<BasketComparisonResponse>> compareBasket(
            @PathVariable UUID homeId,
            @RequestBody BasketComparisonRequest request) {

        BasketComparisonResponse response = priceComparisonService.compareBasket(homeId, request);
        return ResponseEntity.ok(ApiResponse.success("Basket comparison completed", response));
    }

    @PostMapping("/shopping/sessions")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Create a shopping session",
            description = "Records a user's decision process for a basket comparison.")
    public ResponseEntity<ApiResponse<ShoppingSession>> createSession(
            @PathVariable UUID homeId,
            @RequestBody CreateSessionRequest request) {

        UUID userId = SecurityUtils.getCurrentUserId();
        ShoppingSession session = shoppingSessionService.createSession(
                homeId, userId, request.getItemIds(), request.getSelectedProviders(),
                request.getEstimatedTotal(), request.getRecommendedOption());
        return ResponseEntity.ok(ApiResponse.success("Shopping session started", session));
    }

    @PostMapping("/shopping/sessions/{sessionId}/complete")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Complete shopping session and record purchase",
            description = "Transactionally completes shopping session, restocks inventory, marks shopping items complete, and updates consumption learning.")
    public ResponseEntity<ApiResponse<PurchaseDto>> completeSession(
            @PathVariable UUID homeId,
            @PathVariable UUID sessionId,
            @Valid @RequestBody CompleteSessionRequest request) {

        UUID userId = SecurityUtils.getCurrentUserId();
        PurchaseDto purchase = shoppingSessionService.completeSession(homeId, userId, sessionId, request);
        return ResponseEntity.ok(ApiResponse.success("Shopping completed and inventory restocked successfully", purchase));
    }

    @PostMapping("/shopping/local-price")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Report or record local store price",
            description = "Stores user-reported offline/local price for benchmark comparisons.")
    public ResponseEntity<ApiResponse<PriceHistory>> reportLocalPrice(
            @PathVariable UUID homeId,
            @Valid @RequestBody LocalPriceReportRequest request) {

        UUID userId = SecurityUtils.getCurrentUserId();
        PriceHistory record = shoppingSessionService.recordLocalPrice(homeId, userId, request);
        return ResponseEntity.ok(ApiResponse.success("Local price reported", record));
    }

    @GetMapping("/shopping/providers")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "List registered shopping providers",
            description = "Returns all available shopping providers with capability flags and enabled status.")
    public ResponseEntity<ApiResponse<List<ProviderInfoDto>>> getProviders(@PathVariable UUID homeId) {
        List<ProviderInfoDto> providers = providerRegistry.getAllProviders().stream()
                .map(p -> ProviderInfoDto.builder()
                        .name(p.getProviderName())
                        .displayName(p.getDisplayName())
                        .enabled(p.isEnabled())
                        .capabilities(p.getCapabilities())
                        .build())
                .collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success("Providers retrieved", providers));
    }

    @GetMapping("/shopping/price-history")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get price history records",
            description = "Returns recorded price snapshots for trend analysis.")
    public ResponseEntity<ApiResponse<List<PriceHistory>>> getPriceHistory(
            @PathVariable UUID homeId,
            @RequestParam(required = false) UUID productId) {

        List<PriceHistory> history;
        if (productId != null) {
            history = priceHistoryRepository.findByProductIdOrderByRecordedAtDesc(productId);
        } else {
            history = priceHistoryRepository.findTop30ByOrderByRecordedAtDesc();
        }

        return ResponseEntity.ok(ApiResponse.success("Price history retrieved", history));
    }
}
