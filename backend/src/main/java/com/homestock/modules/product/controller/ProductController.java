package com.homestock.modules.product.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.inventory.dto.InventoryItemDto;
import com.homestock.modules.product.dto.BarcodeInventoryRequest;
import com.homestock.modules.product.dto.CreateProductRequest;
import com.homestock.modules.product.dto.ProductDto;
import com.homestock.modules.product.dto.ProductLookupResponse;
import com.homestock.modules.product.service.ProductCatalogService;
import com.homestock.modules.product.service.ProductLookupService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
@Tag(name = "Products & Barcodes", description = "Endpoints for barcode product recognition, catalog lookups, and direct barcode inventory updates")
public class ProductController {

    private final ProductLookupService productLookupService;
    private final ProductCatalogService productCatalogService;

    @GetMapping("/products/barcode/{barcode}")
    @Operation(summary = "Lookup product metadata by barcode with optional home inventory context")
    public ResponseEntity<ApiResponse<ProductLookupResponse>> lookupProduct(
            @PathVariable String barcode,
            @RequestParam(required = false) UUID homeId) {
        ProductLookupResponse response = productLookupService.lookupByBarcode(barcode, homeId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PostMapping("/products")
    @Operation(summary = "Manually add a product to the canonical catalog")
    public ResponseEntity<ApiResponse<ProductDto>> createProduct(
            @Valid @RequestBody CreateProductRequest request) {
        ProductDto created = productCatalogService.createProduct(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(created));
    }

    @PostMapping("/homes/{homeId}/inventory/from-barcode")
    @PreAuthorize("@homeSecurity.canManageInventory(#homeId)")
    @Operation(summary = "Add or update home inventory from scanned barcode with automatic stock transaction audit")
    public ResponseEntity<ApiResponse<InventoryItemDto>> addOrUpdateFromBarcode(
            @PathVariable UUID homeId,
            @Valid @RequestBody BarcodeInventoryRequest request) {
        InventoryItemDto item = productCatalogService.addOrUpdateInventoryFromBarcode(homeId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(item));
    }
}
