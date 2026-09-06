package com.homestock.modules.shopping.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.shopping.dto.CreateShoppingItemRequest;
import com.homestock.modules.shopping.dto.ShoppingListDto;
import com.homestock.modules.shopping.dto.ShoppingListItemDto;
import com.homestock.modules.shopping.dto.UpdateShoppingItemRequest;
import com.homestock.modules.shopping.service.ShoppingService;
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
@RequestMapping("/api/v1/homes/{homeId}/shopping-lists")
@RequiredArgsConstructor
@Tag(name = "Shopping Lists", description = "Endpoints for shared household shopping lists and low-stock replenishment")
public class ShoppingController {

    private final ShoppingService shoppingService;

    @GetMapping("/default")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get active default shopping list for the home")
    public ResponseEntity<ApiResponse<ShoppingListDto>> getDefaultList(@PathVariable UUID homeId) {
        ShoppingListDto list = shoppingService.getDefaultShoppingList(homeId);
        return ResponseEntity.ok(ApiResponse.success(list));
    }

    @PostMapping("/{listId}/items")
    @PreAuthorize("@homeSecurity.canEditShoppingList(#homeId)")
    @Operation(summary = "Add an item to the shopping list")
    public ResponseEntity<ApiResponse<ShoppingListItemDto>> addItem(
            @PathVariable UUID homeId,
            @PathVariable UUID listId,
            @Valid @RequestBody CreateShoppingItemRequest request) {
        ShoppingListItemDto item = shoppingService.addItem(homeId, listId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Item added to shopping list", item));
    }

    @PutMapping("/{listId}/items/{itemId}")
    @PreAuthorize("@homeSecurity.canEditShoppingList(#homeId)")
    @Operation(summary = "Update shopping item quantity or details")
    public ResponseEntity<ApiResponse<ShoppingListItemDto>> updateItem(
            @PathVariable UUID homeId,
            @PathVariable UUID listId,
            @PathVariable UUID itemId,
            @Valid @RequestBody UpdateShoppingItemRequest request) {
        ShoppingListItemDto updated = shoppingService.updateItem(homeId, listId, itemId, request);
        return ResponseEntity.ok(ApiResponse.success("Item updated", updated));
    }

    @PatchMapping("/{listId}/items/{itemId}/toggle")
    @PreAuthorize("@homeSecurity.canEditShoppingList(#homeId)")
    @Operation(summary = "Toggle shopping item purchased/completed state")
    public ResponseEntity<ApiResponse<ShoppingListItemDto>> toggleItem(
            @PathVariable UUID homeId,
            @PathVariable UUID listId,
            @PathVariable UUID itemId) {
        ShoppingListItemDto updated = shoppingService.toggleItem(homeId, listId, itemId);
        return ResponseEntity.ok(ApiResponse.success("Item updated", updated));
    }

    @DeleteMapping("/{listId}/items/{itemId}")
    @PreAuthorize("@homeSecurity.canEditShoppingList(#homeId)")
    @Operation(summary = "Delete an item from shopping list")
    public ResponseEntity<ApiResponse<Void>> deleteItem(
            @PathVariable UUID homeId,
            @PathVariable UUID listId,
            @PathVariable UUID itemId) {
        shoppingService.deleteItem(homeId, listId, itemId);
        return ResponseEntity.ok(ApiResponse.success("Item deleted", null));
    }

    @PostMapping("/{listId}/clear-completed")
    @PreAuthorize("@homeSecurity.canEditShoppingList(#homeId)")
    @Operation(summary = "Clear all completed items from shopping list")
    public ResponseEntity<ApiResponse<Void>> clearCompleted(
            @PathVariable UUID homeId,
            @PathVariable UUID listId) {
        shoppingService.clearCompleted(homeId, listId);
        return ResponseEntity.ok(ApiResponse.success("Completed items cleared", null));
    }
}
