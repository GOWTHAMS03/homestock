package com.homestock.modules.shop.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.shop.dto.ShopSubscriptionResponse;
import com.homestock.modules.shop.dto.SubscriptionPlanResponse;
import com.homestock.modules.shop.service.ShopSubscriptionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
@Tag(name = "Shop Subscriptions", description = "Tier management and limits for shop owners")
public class ShopSubscriptionController {

    private final ShopSubscriptionService subscriptionService;

    @GetMapping("/api/v1/subscription-plans")
    @Operation(summary = "List all available subscription plans")
    public ResponseEntity<ApiResponse<List<SubscriptionPlanResponse>>> getAllPlans() {
        List<SubscriptionPlanResponse> plans = subscriptionService.getAllPlans();
        return ResponseEntity.ok(ApiResponse.success("Subscription plans retrieved", plans));
    }

    @GetMapping("/api/v1/shop-owner/{shopId}/subscription")
    @PreAuthorize("@shopSecurity.canManageShop(#shopId)")
    @Operation(summary = "Get current subscription status and limits for a shop")
    public ResponseEntity<ApiResponse<ShopSubscriptionResponse>> getShopSubscription(
            @PathVariable UUID shopId) {
        ShopSubscriptionResponse sub = subscriptionService.getShopSubscription(shopId);
        return ResponseEntity.ok(ApiResponse.success("Shop subscription retrieved", sub));
    }

    @PostMapping("/api/v1/shop-owner/{shopId}/subscription/upgrade")
    @PreAuthorize("@shopSecurity.isShopOwner(#shopId)")
    @Operation(summary = "Upgrade or change the subscription tier for a shop")
    public ResponseEntity<ApiResponse<ShopSubscriptionResponse>> upgradePlan(
            @PathVariable UUID shopId,
            @RequestParam String plan) {
        ShopSubscriptionResponse upgraded = subscriptionService.upgradePlan(shopId, plan);
        return ResponseEntity.ok(ApiResponse.success("Plan upgraded successfully", upgraded));
    }
}
