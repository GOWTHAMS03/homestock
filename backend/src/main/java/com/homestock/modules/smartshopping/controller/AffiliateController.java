package com.homestock.modules.smartshopping.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.smartshopping.dto.AffiliateClickRequest;
import com.homestock.modules.smartshopping.dto.AffiliateClickResponse;
import com.homestock.modules.smartshopping.service.AffiliateLinkService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/homes/{homeId}/affiliate")
@RequiredArgsConstructor
@Tag(name = "Affiliate Links", description = "Affiliate link tracking and generation")
public class AffiliateController {

    private final AffiliateLinkService affiliateLinkService;

    @PostMapping("/click")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Record affiliate click and get redirect URL",
            description = "Records the click for analytics and returns the appropriate affiliate URL for the provider.")
    public ResponseEntity<ApiResponse<AffiliateClickResponse>> recordClick(
            @PathVariable UUID homeId,
            @Valid @RequestBody AffiliateClickRequest request) {

        AffiliateClickResponse response = affiliateLinkService.recordClickAndGetUrl(homeId, request);
        return ResponseEntity.ok(ApiResponse.success("Click recorded", response));
    }
}
