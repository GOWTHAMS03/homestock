package com.homestock.modules.inventory.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.core.common.PagedResponse;
import com.homestock.modules.inventory.dto.*;
import com.homestock.modules.inventory.service.InventoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/homes/{homeId}/items")
@RequiredArgsConstructor
@Tag(name = "Inventory", description = "Endpoints for household inventory, stock updates, and item audit history")
public class InventoryController {

    private final InventoryService inventoryService;

    @GetMapping
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Search and filter inventory items with pagination")
    public ResponseEntity<ApiResponse<PagedResponse<InventoryItemDto>>> getItems(
            @PathVariable UUID homeId,
            @RequestParam(required = false) UUID categoryId,
            @RequestParam(required = false) String storageLocation,
            @RequestParam(required = false) String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        PagedResponse<InventoryItemDto> response = inventoryService.getItems(
                homeId, categoryId, storageLocation, query, page, size);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping("/{itemId}")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get inventory item by ID")
    public ResponseEntity<ApiResponse<InventoryItemDto>> getItem(
            @PathVariable UUID homeId,
            @PathVariable UUID itemId) {
        InventoryItemDto item = inventoryService.getItemById(homeId, itemId);
        return ResponseEntity.ok(ApiResponse.success(item));
    }

    @PostMapping
    @PreAuthorize("@homeSecurity.canManageInventory(#homeId)")
    @Operation(summary = "Add a new inventory item")
    public ResponseEntity<ApiResponse<InventoryItemDto>> createItem(
            @PathVariable UUID homeId,
            @Valid @RequestBody CreateInventoryItemRequest request) {
        InventoryItemDto created = inventoryService.createItem(homeId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Item added to inventory", created));
    }

    @PutMapping("/{itemId}")
    @PreAuthorize("@homeSecurity.canManageInventory(#homeId)")
    @Operation(summary = "Update inventory item details")
    public ResponseEntity<ApiResponse<InventoryItemDto>> updateItem(
            @PathVariable UUID homeId,
            @PathVariable UUID itemId,
            @Valid @RequestBody UpdateInventoryItemRequest request) {
        InventoryItemDto updated = inventoryService.updateItem(homeId, itemId, request);
        return ResponseEntity.ok(ApiResponse.success("Item updated successfully", updated));
    }

    @PostMapping("/{itemId}/stock")
    @PreAuthorize("@homeSecurity.canManageInventory(#homeId)")
    @Operation(summary = "Update item stock (STOCK_IN, STOCK_OUT, ADJUSTMENT, etc.)")
    public ResponseEntity<ApiResponse<InventoryItemDto>> updateStock(
            @PathVariable UUID homeId,
            @PathVariable UUID itemId,
            @Valid @RequestBody StockUpdateRequest request) {
        InventoryItemDto updated = inventoryService.updateStock(homeId, itemId, request);
        return ResponseEntity.ok(ApiResponse.success("Stock updated", updated));
    }

    @GetMapping("/{itemId}/transactions")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get stock transaction history for an item")
    public ResponseEntity<ApiResponse<PagedResponse<StockTransactionDto>>> getTransactions(
            @PathVariable UUID homeId,
            @PathVariable UUID itemId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        PagedResponse<StockTransactionDto> history = inventoryService.getItemTransactions(homeId, itemId, page, size);
        return ResponseEntity.ok(ApiResponse.success(history));
    }

    @PostMapping(value = "/{itemId}/image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("@homeSecurity.canManageInventory(#homeId)")
    @Operation(summary = "Upload image for an inventory item")
    public ResponseEntity<ApiResponse<InventoryItemDto>> uploadImage(
            @PathVariable UUID homeId,
            @PathVariable UUID itemId,
            @RequestParam("file") MultipartFile file) {
        InventoryItemDto updated = inventoryService.uploadItemImage(homeId, itemId, file);
        return ResponseEntity.ok(ApiResponse.success("Image uploaded successfully", updated));
    }

    @DeleteMapping("/{itemId}")
    @PreAuthorize("@homeSecurity.canManageInventory(#homeId)")
    @Operation(summary = "Archive an inventory item")
    public ResponseEntity<ApiResponse<Void>> deleteItem(
            @PathVariable UUID homeId,
            @PathVariable UUID itemId) {
        inventoryService.deleteItem(homeId, itemId);
        return ResponseEntity.ok(ApiResponse.success("Item removed", null));
    }
}
