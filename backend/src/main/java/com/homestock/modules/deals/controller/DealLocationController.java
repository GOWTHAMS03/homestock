package com.homestock.modules.deals.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.core.util.SecurityUtils;
import com.homestock.modules.deals.dto.AreaSearchResultDto;
import com.homestock.modules.deals.dto.UserLocationPreferenceDto;
import com.homestock.modules.deals.service.LocationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import com.homestock.modules.deals.dto.UserLocationRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/v1/location")
@RequiredArgsConstructor
@Tag(name = "Location Intelligence", description = "Privacy-first user location preferences and manual fallback search")
public class DealLocationController {

    private final LocationService locationService;

    @GetMapping("/preferences")
    @Operation(summary = "Get private user location preference")
    public ResponseEntity<ApiResponse<UserLocationPreferenceDto>> getUserPreferences() {
        UUID userId = SecurityUtils.getCurrentUserId();
        UserLocationPreferenceDto pref = locationService.getUserLocationPreference(userId);
        return ResponseEntity.ok(ApiResponse.success("Location preferences retrieved", pref));
    }

    @PostMapping("/preferences")
    @Operation(summary = "Save or update private user location preference")
    public ResponseEntity<ApiResponse<UserLocationPreferenceDto>> saveUserPreferences(
            @RequestBody UserLocationPreferenceDto dto) {
        UUID userId = SecurityUtils.getCurrentUserId();
        UserLocationPreferenceDto updated = locationService.saveUserLocationPreference(userId, dto);
        return ResponseEntity.ok(ApiResponse.success("Location preferences updated successfully", updated));
    }

    @GetMapping("/search-areas")
    @Operation(summary = "Search fallback cities, areas, and pincodes for manual location")
    public ResponseEntity<ApiResponse<List<AreaSearchResultDto>>> searchAreas(
            @RequestParam(required = false) String q) {
        List<AreaSearchResultDto> areas = locationService.searchAreas(q);
        return ResponseEntity.ok(ApiResponse.success("Matching areas retrieved", areas));
    }

    @GetMapping("/reverse-geocode")
    @Operation(summary = "Reverse geocode latitude and longitude to real-world address")
    public ResponseEntity<ApiResponse<AreaSearchResultDto>> reverseGeocode(
            @RequestParam BigDecimal lat,
            @RequestParam BigDecimal lon) {
        AreaSearchResultDto area = locationService.reverseGeocode(lat, lon);
        return ResponseEntity.ok(ApiResponse.success("Location reverse-geocoded successfully", area));
    }

    @GetMapping("/ip-locate")
    @Operation(summary = "Detect live real physical location from client IP")
    public ResponseEntity<ApiResponse<AreaSearchResultDto>> ipLocate(
            HttpServletRequest request,
            @RequestParam(required = false) String ip) {
        String clientIp = ip;
        if (clientIp == null || clientIp.isBlank()) {
            String xForwardedFor = request.getHeader("X-Forwarded-For");
            if (xForwardedFor != null && !xForwardedFor.isBlank()) {
                clientIp = xForwardedFor.split(",")[0].trim();
            } else {
                clientIp = request.getRemoteAddr();
            }
        }
        AreaSearchResultDto area = locationService.detectIpLocation(clientIp);
        return ResponseEntity.ok(ApiResponse.success("Live IP location detected successfully", area));
    }

    @PostMapping("/validate-context")
    @Operation(summary = "Validate and register current device location context")
    public ResponseEntity<ApiResponse<Map<String, Object>>> validateLocationContext(
            @Valid @RequestBody UserLocationRequest request) {
        UUID userId = SecurityUtils.getCurrentUserId();

        if (!request.isValidTimestamp()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Location timestamp is out of acceptable bounds"));
        }

        log.info("[LOCATION_CONTEXT] Validated client location for user={}: {}",
                userId, request.getMaskedLocation());

        AreaSearchResultDto area = locationService.reverseGeocode(request.getLatitude(), request.getLongitude());

        Map<String, Object> result = new HashMap<>();
        result.put("validated", true);
        result.put("area", area != null ? area.getArea() : "Current Location");
        result.put("city", area != null ? area.getCity() : "Nearby");
        result.put("postalCode", area != null ? area.getPostalCode() : "");

        return ResponseEntity.ok(ApiResponse.success("Location context validated", result));
    }
}
