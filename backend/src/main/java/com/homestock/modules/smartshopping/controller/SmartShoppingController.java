package com.homestock.modules.smartshopping.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.smartshopping.dto.PriceComparisonResponse;
import com.homestock.modules.smartshopping.service.PriceComparisonService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/homes/{homeId}")
@RequiredArgsConstructor
@Tag(name = "Smart Shopping", description = "Price comparison and smart shopping assistant endpoints")
public class SmartShoppingController {

    private final PriceComparisonService priceComparisonService;

    @GetMapping("/shopping-list/items/{itemId}/offers")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get price comparison for a single shopping item",
            description = "Searches all enabled providers for matching products, applies product matching, and returns ranked offers sorted by effective price.")
    public ResponseEntity<ApiResponse<PriceComparisonResponse>> getItemOffers(
            @PathVariable UUID homeId,
            @PathVariable UUID itemId) {

        PriceComparisonResponse comparison = priceComparisonService.compareItem(homeId, itemId);
        return ResponseEntity.ok(ApiResponse.success("Price comparison completed", comparison));
    }
}
