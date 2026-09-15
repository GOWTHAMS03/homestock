package com.homestock.modules.shop.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.shop.dto.ShopDashboardResponse;
import com.homestock.modules.shop.service.ShopAnalyticsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/shop-owner/{shopId}/dashboard")
@RequiredArgsConstructor
@Tag(name = "Shop Owner Dashboard", description = "Aggregated intelligence, views, demand, and inventory health")
public class ShopDashboardController {

    private final ShopAnalyticsService shopAnalyticsService;

    @GetMapping
    @PreAuthorize("@shopSecurity.canManageShop(#shopId)")
    @Operation(summary = "Get shop performance metrics, customer demand insights, and attention items")
    public ResponseEntity<ApiResponse<ShopDashboardResponse>> getDashboard(
            @PathVariable UUID shopId) {
        ShopDashboardResponse dashboard = shopAnalyticsService.getDashboard(shopId);
        return ResponseEntity.ok(ApiResponse.success("Shop dashboard data retrieved", dashboard));
    }
}
