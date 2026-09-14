package com.homestock.modules.deals.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.deals.dto.CreateShopRequestDto;
import com.homestock.modules.deals.dto.NearbyShopDto;
import com.homestock.modules.deals.dto.NearbyShopsResponseDto;
import com.homestock.modules.deals.service.NearbyShopService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping({"/api/v1/shops", "/api/v1/api/v1/shops", "/api/shops"})
@RequiredArgsConstructor
@Tag(name = "Nearby Shops", description = "Discovery and catalog intelligence for physical grocery stores")
public class NearbyShopController {

    private final NearbyShopService nearbyShopService;

    @GetMapping(value = {"/nearby", "/api/v1/nearby-shops"})
    @Operation(summary = "Find nearby grocery stores within radius using geographic grid caching and background OSM sync")
    public ResponseEntity<ApiResponse<Object>> getNearbyShops(
            @RequestParam(required = false) BigDecimal lat,
            @RequestParam(required = false) BigDecimal latitude,
            @RequestParam(required = false) BigDecimal lon,
            @RequestParam(required = false) BigDecimal longitude,
            @RequestParam(defaultValue = "5.0") Double radius,
            @RequestParam(defaultValue = "false") Boolean forceRefresh,
            @RequestParam(defaultValue = "false") Boolean rawList) {

        BigDecimal effectiveLat = latitude != null ? latitude : lat;
        BigDecimal effectiveLon = longitude != null ? longitude : lon;

        NearbyShopsResponseDto response = nearbyShopService.findNearbyShopsResponse(
                effectiveLat, effectiveLon, radius, Boolean.TRUE.equals(forceRefresh));

        if (Boolean.TRUE.equals(rawList)) {
            return ResponseEntity.ok(ApiResponse.success("Nearby grocery shops retrieved", response.getShops()));
        }

        return ResponseEntity.ok(ApiResponse.success("Nearby grocery shops retrieved", response));
    }

    @PostMapping
    @Operation(summary = "Submit a user-generated local grocery store with deduplication and confidence scoring")
    public ResponseEntity<ApiResponse<NearbyShopDto>> createShop(
            @Valid @RequestBody CreateShopRequestDto request) {
        NearbyShopDto created = nearbyShopService.createShop(request);
        return ResponseEntity.ok(ApiResponse.success("Local shop submitted successfully", created));
    }

    @PostMapping("/{shopId}/verify")
    @Operation(summary = "Confirm existence of a physical shop (+15 confidence score)")
    public ResponseEntity<ApiResponse<NearbyShopDto>> verifyShop(@PathVariable UUID shopId) {
        NearbyShopDto verified = nearbyShopService.verifyShop(shopId);
        return ResponseEntity.ok(ApiResponse.success("Shop verified successfully", verified));
    }

    @PostMapping("/{shopId}/report-closed")
    @Operation(summary = "Report a physical shop as closed (-25 confidence score)")
    public ResponseEntity<ApiResponse<NearbyShopDto>> reportShopClosed(@PathVariable UUID shopId) {
        NearbyShopDto reported = nearbyShopService.reportShopClosed(shopId);
        return ResponseEntity.ok(ApiResponse.success("Shop closure reported successfully", reported));
    }

    @GetMapping("/{shopId}/deals")
    @Operation(summary = "Get confirmed product prices and deals for a physical shop")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getShopDeals(@PathVariable UUID shopId) {
        Map<String, Object> shopDeals = nearbyShopService.getShopDeals(shopId);
        return ResponseEntity.ok(ApiResponse.success("Shop deals retrieved", shopDeals));
    }
}
