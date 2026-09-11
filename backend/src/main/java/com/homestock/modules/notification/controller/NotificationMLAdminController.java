package com.homestock.modules.notification.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.notification.dto.MLFeatureVectorDto;
import com.homestock.modules.notification.dto.MLPredictionDto;
import com.homestock.modules.notification.dto.NotificationAnalyticsDto;
import com.homestock.modules.notification.ml.FeatureExtractor;
import com.homestock.modules.notification.ml.StockPredictionService;
import com.homestock.modules.notification.service.NotificationAnalyticsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/notifications/ml")
@RequiredArgsConstructor
@Tag(name = "Notification ML Engine", description = "Admin & diagnostic endpoints for ML stock predictions, features, and engagement analytics")
public class NotificationMLAdminController {

    private final StockPredictionService stockPredictionService;
    private final FeatureExtractor featureExtractor;
    private final InventoryItemRepository inventoryItemRepository;
    private final NotificationAnalyticsService analyticsService;

    @GetMapping("/predictions/{homeId}")
    @Operation(summary = "Get ML depletion predictions for all inventory items in a household")
    public ResponseEntity<ApiResponse<List<MLPredictionDto>>> getPredictionsForHome(@PathVariable UUID homeId) {
        List<InventoryItem> items = inventoryItemRepository.findAllByHomeIdOrderByNameAsc(homeId);
        List<MLPredictionDto> predictions = new ArrayList<>();

        for (InventoryItem item : items) {
            predictions.add(stockPredictionService.getPredictionDto(item, null));
        }

        return ResponseEntity.ok(ApiResponse.success(predictions));
    }

    @GetMapping("/features/{itemId}")
    @Operation(summary = "Inspect extracted ML feature vector for a specific inventory item")
    public ResponseEntity<ApiResponse<MLFeatureVectorDto>> getFeaturesForItem(@PathVariable UUID itemId) {
        InventoryItem item = inventoryItemRepository.findById(itemId)
                .orElseThrow(() -> new IllegalArgumentException("Inventory item not found: " + itemId));

        MLFeatureVectorDto features = featureExtractor.extractFeatures(item, null);
        return ResponseEntity.ok(ApiResponse.success(features));
    }

    @GetMapping("/analytics/{homeId}")
    @Operation(summary = "Get household notification effectiveness, action rates, and suppression metrics")
    public ResponseEntity<ApiResponse<NotificationAnalyticsDto>> getAnalyticsForHome(@PathVariable UUID homeId) {
        NotificationAnalyticsDto analytics = analyticsService.getAnalytics(homeId);
        return ResponseEntity.ok(ApiResponse.success(analytics));
    }
}
