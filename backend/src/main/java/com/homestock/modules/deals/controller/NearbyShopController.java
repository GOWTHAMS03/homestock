package com.homestock.modules.deals.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.deals.dto.NearbyShopDto;
import com.homestock.modules.deals.service.NearbyShopService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping({"/api/v1/shops", "/api/v1/api/v1/shops"})
@RequiredArgsConstructor
@Tag(name = "Nearby Shops", description = "Discovery and catalog intelligence for physical grocery stores")
public class NearbyShopController {

    private final NearbyShopService nearbyShopService;

    @GetMapping(value = {"/nearby", "/api/v1/nearby-shops"})
    @Operation(summary = "Find nearby grocery stores within radius (2km default, 5km, 10km) using OpenStreetMap")
    public ResponseEntity<ApiResponse<List<NearbyShopDto>>> getNearbyShops(
            @RequestParam(required = false) BigDecimal lat,
            @RequestParam(required = false) BigDecimal lon,
            @RequestParam(defaultValue = "5.0") Double radius,
            @RequestParam(defaultValue = "false") Boolean forceRefresh) {

        List<NearbyShopDto> shops = nearbyShopService.findNearbyShops(
                lat, lon, radius, Boolean.TRUE.equals(forceRefresh));
        return ResponseEntity.ok(ApiResponse.success("Nearby grocery shops retrieved", shops));
    }

    @GetMapping("/{shopId}/deals")
    @Operation(summary = "Get confirmed product prices and deals for a physical shop")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getShopDeals(@PathVariable UUID shopId) {
        Map<String, Object> shopDeals = nearbyShopService.getShopDeals(shopId);
        return ResponseEntity.ok(ApiResponse.success("Shop deals retrieved", shopDeals));
    }
}
