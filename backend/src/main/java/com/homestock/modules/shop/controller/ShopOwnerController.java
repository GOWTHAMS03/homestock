package com.homestock.modules.shop.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.shop.dto.ShopProfileResponse;
import com.homestock.modules.shop.dto.ShopRegistrationRequest;
import com.homestock.modules.shop.service.ShopOwnerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/shop-owner")
@RequiredArgsConstructor
@Tag(name = "Shop Owner Operations", description = "Shop registration and profile management for shop owners")
public class ShopOwnerController {

    private final ShopOwnerService shopOwnerService;

    @PostMapping("/register")
    @Operation(summary = "Register a new physical shop (sets status to PENDING and role to SHOP_OWNER)")
    public ResponseEntity<ApiResponse<ShopProfileResponse>> registerShop(
            @Valid @RequestBody ShopRegistrationRequest request) {
        ShopProfileResponse response = shopOwnerService.registerShop(request);
        return ResponseEntity.ok(ApiResponse.success("Shop registered successfully and submitted for verification", response));
    }

    @GetMapping("/my-shop")
    @Operation(summary = "Get the shop profile owned by the currently authenticated user")
    public ResponseEntity<ApiResponse<ShopProfileResponse>> getMyShop() {
        ShopProfileResponse response = shopOwnerService.getMyShop();
        return ResponseEntity.ok(ApiResponse.success("Shop profile retrieved", response));
    }

    @GetMapping("/{shopId}")
    @PreAuthorize("@shopSecurity.canManageShop(#shopId)")
    @Operation(summary = "Get shop profile by ID (Owner or Admin)")
    public ResponseEntity<ApiResponse<ShopProfileResponse>> getShopById(@PathVariable UUID shopId) {
        ShopProfileResponse response = shopOwnerService.getShopProfile(shopId);
        return ResponseEntity.ok(ApiResponse.success("Shop profile retrieved", response));
    }

    @PutMapping("/{shopId}")
    @PreAuthorize("@shopSecurity.isShopOwner(#shopId) or @shopSecurity.isAdmin()")
    @Operation(summary = "Update shop profile information")
    public ResponseEntity<ApiResponse<ShopProfileResponse>> updateShopProfile(
            @PathVariable UUID shopId,
            @RequestBody ShopRegistrationRequest request) {
        ShopProfileResponse response = shopOwnerService.updateShopProfile(shopId, request);
        return ResponseEntity.ok(ApiResponse.success("Shop profile updated successfully", response));
    }
}
