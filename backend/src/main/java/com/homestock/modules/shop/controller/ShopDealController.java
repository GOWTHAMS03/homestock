package com.homestock.modules.shop.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.shop.dto.ShopDealRequest;
import com.homestock.modules.shop.dto.ShopDealResponse;
import com.homestock.modules.shop.service.ShopOwnerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/shop-owner/{shopId}/deals")
@RequiredArgsConstructor
@Tag(name = "Shop Deals Management", description = "Create and manage promotional offers and discounts")
public class ShopDealController {

    private final ShopOwnerService shopOwnerService;

    @GetMapping
    @PreAuthorize("@shopSecurity.canManageShop(#shopId)")
    @Operation(summary = "Get all promotional deals for this shop")
    public ResponseEntity<ApiResponse<List<ShopDealResponse>>> getShopDeals(
            @PathVariable UUID shopId) {
        List<ShopDealResponse> deals = shopOwnerService.getShopDeals(shopId);
        return ResponseEntity.ok(ApiResponse.success("Shop deals retrieved", deals));
    }

    @PostMapping
    @PreAuthorize("@shopSecurity.isShopOwner(#shopId)")
    @Operation(summary = "Create a new deal or discount for this shop")
    public ResponseEntity<ApiResponse<ShopDealResponse>> createDeal(
            @PathVariable UUID shopId,
            @Valid @RequestBody ShopDealRequest request) {
        ShopDealResponse deal = shopOwnerService.createDeal(shopId, request);
        return ResponseEntity.ok(ApiResponse.success("Deal created successfully", deal));
    }

    @PutMapping("/{dealId}")
    @PreAuthorize("@shopSecurity.isShopOwner(#shopId)")
    @Operation(summary = "Update an existing deal")
    public ResponseEntity<ApiResponse<ShopDealResponse>> updateDeal(
            @PathVariable UUID shopId,
            @PathVariable UUID dealId,
            @RequestBody ShopDealRequest request) {
        ShopDealResponse updated = shopOwnerService.updateDeal(shopId, dealId, request);
        return ResponseEntity.ok(ApiResponse.success("Deal updated successfully", updated));
    }

    @DeleteMapping("/{dealId}")
    @PreAuthorize("@shopSecurity.isShopOwner(#shopId)")
    @Operation(summary = "Deactivate/delete a deal")
    public ResponseEntity<ApiResponse<Void>> deleteDeal(
            @PathVariable UUID shopId,
            @PathVariable UUID dealId) {
        shopOwnerService.deleteDeal(shopId, dealId);
        return ResponseEntity.ok(ApiResponse.success("Deal deleted successfully", null));
    }
}
