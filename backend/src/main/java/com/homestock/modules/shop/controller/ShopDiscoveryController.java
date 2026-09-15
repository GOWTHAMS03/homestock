package com.homestock.modules.shop.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.shop.dto.ShopDealResponse;
import com.homestock.modules.shop.dto.ShopProductResponse;
import com.homestock.modules.shop.dto.ShopProfileResponse;
import com.homestock.modules.shop.service.ShopDiscoveryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/discovery")
@RequiredArgsConstructor
@Tag(name = "Customer Discovery", description = "Location-aware verified shop and product discovery for shoppers")
public class ShopDiscoveryController {

    private final ShopDiscoveryService shopDiscoveryService;
    private final com.homestock.modules.shop.service.AsyncDemandEventService asyncDemandEventService;

    @GetMapping("/shops")
    @Operation(summary = "Discover verified local shops within radius")
    public ResponseEntity<ApiResponse<List<ShopProfileResponse>>> getNearbyShops(
            @RequestParam(required = false) BigDecimal lat,
            @RequestParam(required = false) BigDecimal latitude,
            @RequestParam(required = false) BigDecimal lon,
            @RequestParam(required = false) BigDecimal longitude,
            @RequestParam(defaultValue = "5.0") Double radius) {

        BigDecimal effectiveLat = latitude != null ? latitude : lat;
        BigDecimal effectiveLon = longitude != null ? longitude : lon;

        List<ShopProfileResponse> shops = shopDiscoveryService.findNearbyVerifiedShops(
                effectiveLat, effectiveLon, radius != null ? radius : 5.0);

        return ResponseEntity.ok(ApiResponse.success("Nearby verified shops discovered", shops));
    }

    @GetMapping("/products")
    @Operation(summary = "Search products across nearby verified shops with real-time pricing and stock status")
    public ResponseEntity<ApiResponse<List<ShopProductResponse>>> searchProducts(
            @RequestParam String query,
            @RequestParam(required = false) BigDecimal lat,
            @RequestParam(required = false) BigDecimal latitude,
            @RequestParam(required = false) BigDecimal lon,
            @RequestParam(required = false) BigDecimal longitude,
            @RequestParam(defaultValue = "5.0") Double radius,
            @RequestParam(defaultValue = "NEAREST") String sortBy) {

        BigDecimal effectiveLat = latitude != null ? latitude : lat;
        BigDecimal effectiveLon = longitude != null ? longitude : lon;

        List<ShopProductResponse> results = shopDiscoveryService.searchProductsNearby(
                query, effectiveLat, effectiveLon, radius != null ? radius : 5.0, sortBy);

        asyncDemandEventService.recordEvent(
                com.homestock.modules.shop.entity.DemandEventType.NEARBY_SEARCH,
                query,
                null,
                null,
                effectiveLat,
                effectiveLon
        );

        return ResponseEntity.ok(ApiResponse.success("Nearby products found", results));
    }

    @GetMapping("/shops/{shopId}")
    @Operation(summary = "Get customer-facing shop details including verified badge, hours, contact, and deal count")
    public ResponseEntity<ApiResponse<ShopProfileResponse>> getShopProfile(
            @PathVariable UUID shopId,
            @RequestParam(required = false) BigDecimal lat,
            @RequestParam(required = false) BigDecimal lon) {
        ShopProfileResponse profile = shopDiscoveryService.getShopProfile(shopId, lat, lon);
        return ResponseEntity.ok(ApiResponse.success("Shop profile retrieved", profile));
    }

    @GetMapping("/shops/{shopId}/products")
    @Operation(summary = "Get available products for a shop (customer-facing)")
    public ResponseEntity<ApiResponse<List<ShopProductResponse>>> getShopProducts(
            @PathVariable UUID shopId) {
        List<ShopProductResponse> products = shopDiscoveryService.getShopProductsForCustomer(shopId);
        return ResponseEntity.ok(ApiResponse.success("Shop products retrieved", products));
    }

    @GetMapping("/shops/{shopId}/deals")
    @Operation(summary = "Get active promotional deals for a shop (customer-facing)")
    public ResponseEntity<ApiResponse<List<ShopDealResponse>>> getShopDeals(
            @PathVariable UUID shopId) {
        List<ShopDealResponse> deals = shopDiscoveryService.getShopActiveDeals(shopId);
        return ResponseEntity.ok(ApiResponse.success("Shop deals retrieved", deals));
    }
}
