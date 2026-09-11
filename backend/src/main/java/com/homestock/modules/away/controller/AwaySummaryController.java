package com.homestock.modules.away.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.core.util.SecurityUtils;
import com.homestock.modules.away.dto.*;
import com.homestock.modules.away.entity.AwayPrediction;
import com.homestock.modules.away.entity.UserActivityType;
import com.homestock.modules.away.service.AwaySummaryService;
import com.homestock.modules.away.service.PredictionFeedbackService;
import com.homestock.modules.home.entity.HomeMember;
import com.homestock.modules.home.repository.HomeMemberRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
@Tag(name = "While You Were Away", description = "Smart Household Gap Intelligence & Return Prediction APIs")
public class AwaySummaryController {

    private final AwaySummaryService awaySummaryService;
    private final PredictionFeedbackService feedbackService;
    private final HomeMemberRepository homeMemberRepository;

    @GetMapping("/away-summary")
    @Operation(summary = "Get 'While You Were Away' smart summary for current user's household")
    public ResponseEntity<ApiResponse<AwaySummaryResponseDto>> getAwaySummary(
            @RequestParam(required = false) UUID homeId
    ) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        UUID targetHomeId = resolveHomeId(currentUserId, homeId);

        AwaySummaryResponseDto response = awaySummaryService.getAwaySummary(currentUserId, targetHomeId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping("/homes/{homeId}/away-summary")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get 'While You Were Away' summary for a specific home")
    public ResponseEntity<ApiResponse<AwaySummaryResponseDto>> getHomeAwaySummary(
            @PathVariable UUID homeId
    ) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        AwaySummaryResponseDto response = awaySummaryService.getAwaySummary(currentUserId, homeId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PostMapping("/away-summary/heartbeat")
    @Operation(summary = "Record user app activity / heartbeat to track presence")
    public ResponseEntity<ApiResponse<Map<String, String>>> recordHeartbeat(
            @RequestBody(required = false) UserActivityHeartbeatRequest request
    ) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        UUID homeId = request != null && request.getHomeId() != null
                ? request.getHomeId()
                : resolveHomeId(currentUserId, null);

        UserActivityType type = request != null && request.getActivityType() != null
                ? request.getActivityType()
                : UserActivityType.APP_OPEN;

        String metadata = request != null ? request.getMetadata() : null;

        awaySummaryService.recordHeartbeat(currentUserId, homeId, type, metadata);
        return ResponseEntity.ok(ApiResponse.success(Map.of("status", "HEARTBEAT_RECORDED")));
    }

    @PostMapping("/away-summary/item/{predictionId}/confirm")
    @Operation(summary = "User confirms estimated stock ('Looks right'), safely updating inventory")
    public ResponseEntity<ApiResponse<Map<String, Object>>> confirmPrediction(
            @PathVariable UUID predictionId
    ) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        AwayPrediction updated = feedbackService.acceptPrediction(predictionId, currentUserId);

        return ResponseEntity.ok(ApiResponse.success(Map.of(
                "status", "ACCEPTED",
                "predictionId", updated.getId(),
                "itemId", updated.getInventoryItem().getId(),
                "confirmedQuantity", updated.getEstimatedQuantity()
        )));
    }

    @PostMapping("/away-summary/item/{predictionId}/correct")
    @Operation(summary = "User inputs verified stock ('Update stock'), updating inventory and learning correction factor")
    public ResponseEntity<ApiResponse<Map<String, Object>>> correctPrediction(
            @PathVariable UUID predictionId,
            @Valid @RequestBody PredictionCorrectRequest request
    ) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        AwayPrediction updated = feedbackService.correctPrediction(predictionId, request.getActualQuantity(), currentUserId);

        return ResponseEntity.ok(ApiResponse.success(Map.of(
                "status", "CORRECTED",
                "predictionId", updated.getId(),
                "itemId", updated.getInventoryItem().getId(),
                "correctedQuantity", request.getActualQuantity()
        )));
    }

    @PostMapping("/away-summary/item/{predictionId}/dismiss")
    @Operation(summary = "User dismisses an item prediction from the summary")
    public ResponseEntity<ApiResponse<Map<String, Object>>> dismissPrediction(
            @PathVariable UUID predictionId
    ) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        AwayPrediction dismissed = feedbackService.dismissPrediction(predictionId, currentUserId);

        return ResponseEntity.ok(ApiResponse.success(Map.of(
                "status", "DISMISSED",
                "predictionId", dismissed.getId()
        )));
    }

    @PostMapping("/away-summary/add-to-shopping-list")
    @Operation(summary = "1-tap add predicted low / ran out items to household shopping list")
    public ResponseEntity<ApiResponse<Map<String, Object>>> addToShoppingList(
            @RequestParam(required = false) UUID homeId,
            @RequestBody(required = false) AddPredictedToShoppingRequest request
    ) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        UUID targetHomeId = resolveHomeId(currentUserId, homeId);

        List<UUID> predIds = request != null ? request.getPredictionIds() : null;
        int count = awaySummaryService.addPredictedItemsToShoppingList(currentUserId, targetHomeId, predIds);

        return ResponseEntity.ok(ApiResponse.success(Map.of(
                "status", "ITEMS_ADDED_TO_SHOPPING_LIST",
                "addedCount", count,
                "homeId", targetHomeId
        )));
    }

    @PostMapping("/away-summary/{summaryId}/dismiss-all")
    @Operation(summary = "Dismiss the entire away summary")
    public ResponseEntity<ApiResponse<Map<String, String>>> dismissAll(
            @PathVariable UUID summaryId
    ) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        awaySummaryService.dismissAll(summaryId, currentUserId);
        return ResponseEntity.ok(ApiResponse.success(Map.of("status", "SUMMARY_DISMISSED")));
    }

    private UUID resolveHomeId(UUID userId, UUID requestedHomeId) {
        if (requestedHomeId != null) {
            return requestedHomeId;
        }
        List<HomeMember> memberships = homeMemberRepository.findAllByUserId(userId);
        if (memberships.isEmpty()) {
            throw new ResourceNotFoundException("No active household found for user: " + userId);
        }
        return memberships.getFirst().getHome().getId();
    }
}
