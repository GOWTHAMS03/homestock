package com.homestock.modules.store.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.store.dto.CreateStoreRequest;
import com.homestock.modules.store.dto.StoreDto;
import com.homestock.modules.store.service.StoreService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/homes/{homeId}/stores")
@RequiredArgsConstructor
@Tag(name = "Stores", description = "Endpoints for managing frequented shopping stores")
public class StoreController {

    private final StoreService storeService;

    @GetMapping
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get all frequented stores for a home")
    public ResponseEntity<ApiResponse<List<StoreDto>>> getStores(@PathVariable UUID homeId) {
        List<StoreDto> stores = storeService.getStoresForHome(homeId);
        return ResponseEntity.ok(ApiResponse.success(stores));
    }

    @PostMapping
    @PreAuthorize("@homeSecurity.canManageInventory(#homeId)")
    @Operation(summary = "Add a new store")
    public ResponseEntity<ApiResponse<StoreDto>> createStore(
            @PathVariable UUID homeId,
            @Valid @RequestBody CreateStoreRequest request) {
        StoreDto store = storeService.createStore(homeId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Store added successfully", store));
    }
}
