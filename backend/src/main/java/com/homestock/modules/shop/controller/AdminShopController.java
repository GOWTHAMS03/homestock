package com.homestock.modules.shop.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.shop.dto.ShopProfileResponse;
import com.homestock.modules.shop.service.ShopOwnerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/admin/shops")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
@Tag(name = "Admin Shop Management", description = "Shop verification, approval, rejection, and suspension controls")
public class AdminShopController {

    private final ShopOwnerService shopOwnerService;

    @GetMapping
    @Operation(summary = "Get shops by verification status (PENDING, VERIFIED, REJECTED, SUSPENDED)")
    public ResponseEntity<ApiResponse<List<ShopProfileResponse>>> getShopsByStatus(
            @RequestParam(defaultValue = "PENDING") String status) {
        List<ShopProfileResponse> shops = shopOwnerService.getShopsByStatus(status.toUpperCase());
        return ResponseEntity.ok(ApiResponse.success("Shops retrieved", shops));
    }

    @PostMapping("/{shopId}/verify")
    @Operation(summary = "Verify and approve a registered shop (+30 confidence score, enabled for customer discovery)")
    public ResponseEntity<ApiResponse<ShopProfileResponse>> verifyShop(@PathVariable UUID shopId) {
        ShopProfileResponse verified = shopOwnerService.verifyShop(shopId);
        return ResponseEntity.ok(ApiResponse.success("Shop approved and verified successfully", verified));
    }

    @PostMapping("/{shopId}/reject")
    @Operation(summary = "Reject a shop registration with an optional reason")
    public ResponseEntity<ApiResponse<ShopProfileResponse>> rejectShop(
            @PathVariable UUID shopId,
            @RequestBody(required = false) Map<String, String> body) {
        String reason = body != null ? body.get("reason") : null;
        ShopProfileResponse rejected = shopOwnerService.rejectShop(shopId, reason);
        return ResponseEntity.ok(ApiResponse.success("Shop registration rejected", rejected));
    }

    @PostMapping("/{shopId}/suspend")
    @Operation(summary = "Suspend an active shop (removes from customer discovery)")
    public ResponseEntity<ApiResponse<ShopProfileResponse>> suspendShop(
            @PathVariable UUID shopId,
            @RequestBody(required = false) Map<String, String> body) {
        String reason = body != null ? body.get("reason") : null;
        ShopProfileResponse suspended = shopOwnerService.suspendShop(shopId, reason);
        return ResponseEntity.ok(ApiResponse.success("Shop suspended successfully", suspended));
    }
}
