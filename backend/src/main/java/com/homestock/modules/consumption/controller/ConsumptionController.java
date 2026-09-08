package com.homestock.modules.consumption.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.consumption.dto.*;
import com.homestock.modules.consumption.entity.RecommendationUrgency;
import com.homestock.modules.consumption.service.ConsumptionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Tag(name = "Consumption Engine", description = "Zero-Manual-Tracking & Smart Consumption Intelligence APIs")
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class ConsumptionController {

    private final ConsumptionService consumptionService;

    @Operation(summary = "Get learned consumption profile for an item")
    @GetMapping("/homes/{homeId}/consumption/{itemId}")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    public ResponseEntity<ApiResponse<ConsumptionProfileDto>> getItemConsumption(
            @PathVariable UUID homeId,
            @PathVariable UUID itemId) {
        ConsumptionProfileDto dto = consumptionService.getConsumptionProfile(homeId, itemId);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @Operation(summary = "Get all consumption profiles for a household")
    @GetMapping("/homes/{homeId}/consumption")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    public ResponseEntity<ApiResponse<List<ConsumptionProfileDto>>> getAllConsumption(
            @PathVariable UUID homeId) {
        List<ConsumptionProfileDto> dtos = consumptionService.getAllConsumptionProfiles(homeId);
        return ResponseEntity.ok(ApiResponse.success(dtos));
    }

    @Operation(summary = "Get stock depletion predictions for all items in a home")
    @GetMapping("/homes/{homeId}/predictions")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    public ResponseEntity<ApiResponse<List<PredictionDto>>> getPredictions(
            @PathVariable UUID homeId) {
        List<PredictionDto> predictions = consumptionService.getAllPredictions(homeId);
        return ResponseEntity.ok(ApiResponse.success(predictions));
    }

    @Operation(summary = "What Do I Need? categorized restock recommendations")
    @GetMapping(value = {"/homes/{homeId}/recommendations", "/homes/{homeId}/what-do-i-need"})
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    public ResponseEntity<ApiResponse<Map<RecommendationUrgency, List<SmartRecommendationDto>>>> getRecommendations(
            @PathVariable UUID homeId) {
        Map<RecommendationUrgency, List<SmartRecommendationDto>> recommendations = consumptionService.getSmartRecommendations(homeId);
        return ResponseEntity.ok(ApiResponse.success(recommendations));
    }

    @Operation(summary = "Fast 2-tap qualitative status confirmation (e.g. About Half, Still have enough)")
    @PostMapping("/items/{itemId}/confirm-status")
    public ResponseEntity<ApiResponse<PredictionDto>> confirmStatus(
            @PathVariable UUID itemId,
            @RequestBody ConfirmStatusRequest request) {
        PredictionDto result = consumptionService.confirmStatus(itemId, request);
        return ResponseEntity.ok(ApiResponse.success(result));
    }

    @Operation(summary = "Confirm exact stock quantity")
    @PostMapping("/items/{itemId}/confirm-quantity")
    public ResponseEntity<ApiResponse<PredictionDto>> confirmQuantity(
            @PathVariable UUID itemId,
            @Valid @RequestBody ConfirmQuantityRequest request) {
        PredictionDto result = consumptionService.confirmQuantity(itemId, request);
        return ResponseEntity.ok(ApiResponse.success(result));
    }

    @Operation(summary = "Get Home Memory insights and learned household rhythms")
    @GetMapping("/homes/{homeId}/insights")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    public ResponseEntity<ApiResponse<HomeMemoryInsightDto>> getHomeInsights(
            @PathVariable UUID homeId) {
        HomeMemoryInsightDto dto = consumptionService.getHomeMemoryInsights(homeId);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @Operation(summary = "Get Return Experience summary after a gap of inactivity")
    @GetMapping("/homes/{homeId}/return-summary")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    public ResponseEntity<ApiResponse<ReturnSummaryDto>> getReturnSummary(
            @PathVariable UUID homeId,
            @RequestParam(defaultValue = "7") int daysAway) {
        ReturnSummaryDto dto = consumptionService.getReturnSummary(homeId, daysAway);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }
}
