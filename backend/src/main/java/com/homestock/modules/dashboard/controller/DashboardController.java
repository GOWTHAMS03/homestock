package com.homestock.modules.dashboard.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.dashboard.dto.DashboardSummaryDto;
import com.homestock.modules.dashboard.dto.WhatDoINeedResponse;
import com.homestock.modules.dashboard.service.DashboardService;
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
@RequestMapping("/api/v1/homes/{homeId}/dashboard")
@RequiredArgsConstructor
@Tag(name = "Dashboard", description = "Endpoints for consumer home dashboard and smart recommendations")
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get home dashboard overview, counts, and needs-attention alerts")
    public ResponseEntity<ApiResponse<DashboardSummaryDto>> getDashboardSummary(@PathVariable UUID homeId) {
        DashboardSummaryDto summary = dashboardService.getDashboardSummary(homeId);
        return ResponseEntity.ok(ApiResponse.success(summary));
    }

    @GetMapping("/what-do-i-need")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Smart replenishment recommendations (URGENT, SOON, OPTIONAL)")
    public ResponseEntity<ApiResponse<WhatDoINeedResponse>> getWhatDoINeed(@PathVariable UUID homeId) {
        WhatDoINeedResponse recommendations = dashboardService.getWhatDoINeed(homeId);
        return ResponseEntity.ok(ApiResponse.success(recommendations));
    }
}
