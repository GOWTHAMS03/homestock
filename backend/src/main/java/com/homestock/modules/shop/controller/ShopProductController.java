package com.homestock.modules.shop.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.shop.dto.ShopProductRequest;
import com.homestock.modules.shop.dto.ShopProductResponse;
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
@RequestMapping("/api/v1/shop-owner/{shopId}/products")
@RequiredArgsConstructor
@Tag(name = "Shop Products Management", description = "CRUD operations for a shop's product inventory")
public class ShopProductController {

    private final ShopOwnerService shopOwnerService;

    @GetMapping
    @PreAuthorize("@shopSecurity.canManageShop(#shopId)")
    @Operation(summary = "Get all products in the shop's catalog (with stock quantities)")
    public ResponseEntity<ApiResponse<List<ShopProductResponse>>> getShopProducts(
            @PathVariable UUID shopId) {
        List<ShopProductResponse> products = shopOwnerService.getShopProducts(shopId);
        return ResponseEntity.ok(ApiResponse.success("Shop products retrieved", products));
    }

    @PostMapping
    @PreAuthorize("@shopSecurity.isShopOwner(#shopId)")
    @Operation(summary = "Add a new product to the shop's catalog")
    public ResponseEntity<ApiResponse<ShopProductResponse>> addProduct(
            @PathVariable UUID shopId,
            @Valid @RequestBody ShopProductRequest request) {
        ShopProductResponse product = shopOwnerService.addProduct(shopId, request);
        return ResponseEntity.ok(ApiResponse.success("Product added successfully", product));
    }

    @PutMapping("/{productId}")
    @PreAuthorize("@shopSecurity.isShopOwner(#shopId)")
    @Operation(summary = "Update an existing product's price, stock, or details (tracks price history)")
    public ResponseEntity<ApiResponse<ShopProductResponse>> updateProduct(
            @PathVariable UUID shopId,
            @PathVariable UUID productId,
            @RequestBody ShopProductRequest request) {
        ShopProductResponse updated = shopOwnerService.updateProduct(shopId, productId, request);
        return ResponseEntity.ok(ApiResponse.success("Product updated successfully", updated));
    }

    @DeleteMapping("/{productId}")
    @PreAuthorize("@shopSecurity.isShopOwner(#shopId)")
    @Operation(summary = "Remove a product from the shop's catalog")
    public ResponseEntity<ApiResponse<Void>> deleteProduct(
            @PathVariable UUID shopId,
            @PathVariable UUID productId) {
        shopOwnerService.deleteProduct(shopId, productId);
        return ResponseEntity.ok(ApiResponse.success("Product deleted successfully", null));
    }
}
