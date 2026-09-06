package com.homestock.modules.analytics.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.analytics.dto.AnalyticsOverviewDto;
import com.homestock.modules.analytics.service.AnalyticsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/homes/{homeId}/analytics")
@RequiredArgsConstructor
@Tag(name = "Analytics", description = "Endpoints for household spending and product consumption analytics")
public class AnalyticsController {

    private final AnalyticsService analyticsService;

    @GetMapping
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get monthly spending, category breakdown, and top purchased items")
    public ResponseEntity<ApiResponse<AnalyticsOverviewDto>> getAnalytics(@PathVariable UUID homeId) {
        AnalyticsOverviewDto data = analyticsService.getOverview(homeId);
        return ResponseEntity.ok(ApiResponse.success(data));
    }
}
