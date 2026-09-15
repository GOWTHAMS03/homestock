package com.homestock.modules.shop.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.shop.dto.demand.CustomerDemandDashboardResponse;
import com.homestock.modules.shop.dto.demand.DemandPeriod;
import com.homestock.modules.shop.dto.demand.ProductDemandDetailResponse;
import com.homestock.modules.shop.service.CustomerDemandService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/shop-owner/{shopId}/demand")
@RequiredArgsConstructor
@Tag(name = "Customer Demand Intelligence", description = "Location-aware aggregated customer demand and sales opportunity insights for shop owners")
public class CustomerDemandController {

    private final CustomerDemandService demandService;

    @GetMapping
    @PreAuthorize("@shopSecurity.canManageShop(#shopId)")
    @Operation(summary = "Get aggregated customer demand dashboard and opportunities for a shop")
    public ResponseEntity<ApiResponse<CustomerDemandDashboardResponse>> getShopDemandDashboard(
            @PathVariable UUID shopId,
            @RequestParam(defaultValue = "LAST_7_DAYS") String period,
            @RequestParam(defaultValue = "5.0") Double radius) {

        DemandPeriod demandPeriod = DemandPeriod.fromString(period);
        CustomerDemandDashboardResponse dashboard = demandService.getShopDemandDashboard(shopId, demandPeriod, radius);

        return ResponseEntity.ok(ApiResponse.success("Demand intelligence retrieved successfully", dashboard));
    }

    @GetMapping("/search")
    @PreAuthorize("@shopSecurity.canManageShop(#shopId)")
    @Operation(summary = "Search customer demand details for an individual product or query")
    public ResponseEntity<ApiResponse<ProductDemandDetailResponse>> searchProductDemand(
            @PathVariable UUID shopId,
            @RequestParam String query,
            @RequestParam(defaultValue = "5.0") Double radius) {

        ProductDemandDetailResponse detail = demandService.searchProductDemandDetail(shopId, query, radius);

        return ResponseEntity.ok(ApiResponse.success("Product demand detail retrieved", detail));
    }
}
