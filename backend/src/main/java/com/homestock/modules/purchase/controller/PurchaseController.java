package com.homestock.modules.purchase.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.core.common.PagedResponse;
import com.homestock.modules.purchase.dto.CreatePurchaseRequest;
import com.homestock.modules.purchase.dto.PurchaseDto;
import com.homestock.modules.purchase.service.PurchaseService;
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
@RequestMapping("/api/v1/homes/{homeId}/purchases")
@RequiredArgsConstructor
@Tag(name = "Purchases", description = "Endpoints for recording purchases, receipts, and automatic inventory replenishment")
public class PurchaseController {

    private final PurchaseService purchaseService;

    @PostMapping
    @PreAuthorize("@homeSecurity.canManageInventory(#homeId)")
    @Operation(summary = "Record a household purchase and update inventory stock atomically")
    public ResponseEntity<ApiResponse<PurchaseDto>> recordPurchase(
            @PathVariable UUID homeId,
            @Valid @RequestBody CreatePurchaseRequest request) {
        PurchaseDto purchase = purchaseService.recordPurchase(homeId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Purchase recorded successfully", purchase));
    }

    @GetMapping
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get paginated purchase history for a home")
    public ResponseEntity<ApiResponse<PagedResponse<PurchaseDto>>> getPurchases(
            @PathVariable UUID homeId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        PagedResponse<PurchaseDto> purchases = purchaseService.getPurchases(homeId, page, size);
        return ResponseEntity.ok(ApiResponse.success(purchases));
    }

    @GetMapping("/{purchaseId}")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get purchase details by ID")
    public ResponseEntity<ApiResponse<PurchaseDto>> getPurchase(
            @PathVariable UUID homeId,
            @PathVariable UUID purchaseId) {
        PurchaseDto purchase = purchaseService.getPurchaseById(homeId, purchaseId);
        return ResponseEntity.ok(ApiResponse.success(purchase));
    }
}
