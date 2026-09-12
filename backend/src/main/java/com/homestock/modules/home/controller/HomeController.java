package com.homestock.modules.home.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.home.dto.*;
import com.homestock.modules.home.service.HomeService;
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
@RequestMapping("/api/v1/homes")
@RequiredArgsConstructor
@Tag(name = "Homes & Members", description = "Endpoints for home management, invitations, and member access")
public class HomeController {

    private final HomeService homeService;

    @GetMapping
    @Operation(summary = "List all homes the authenticated user belongs to")
    public ResponseEntity<ApiResponse<List<HomeDto>>> getMyHomes() {
        List<HomeDto> homes = homeService.getCurrentUserHomes();
        return ResponseEntity.ok(ApiResponse.success(homes));
    }

    @PostMapping
    @Operation(summary = "Create a new home and become OWNER")
    public ResponseEntity<ApiResponse<HomeDto>> createHome(@Valid @RequestBody CreateHomeRequest request) {
        HomeDto home = homeService.createHome(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Home created successfully", home));
    }

    @PostMapping("/join")
    @Operation(summary = "Join an existing home using an invite code")
    public ResponseEntity<ApiResponse<HomeDto>> joinHome(@Valid @RequestBody JoinHomeRequest request) {
        HomeDto home = homeService.joinHome(request);
        return ResponseEntity.ok(ApiResponse.success("Joined home successfully", home));
    }

    @GetMapping("/{homeId}")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get home details by ID")
    public ResponseEntity<ApiResponse<HomeDto>> getHome(@PathVariable UUID homeId) {
        HomeDto home = homeService.getHomeById(homeId);
        return ResponseEntity.ok(ApiResponse.success(home));
    }

    @PutMapping("/{homeId}")
    @PreAuthorize("@homeSecurity.hasPermission(#homeId, T(com.homestock.modules.home.entity.HomeRole).ADMIN)")
    @Operation(summary = "Update home details (ADMIN/OWNER)")
    public ResponseEntity<ApiResponse<HomeDto>> updateHome(
            @PathVariable UUID homeId,
            @Valid @RequestBody UpdateHomeRequest request) {
        HomeDto home = homeService.updateHome(homeId, request);
        return ResponseEntity.ok(ApiResponse.success("Home updated successfully", home));
    }

    @GetMapping("/{homeId}/members")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "List all members of a home")
    public ResponseEntity<ApiResponse<List<HomeMemberDto>>> getMembers(@PathVariable UUID homeId) {
        List<HomeMemberDto> members = homeService.getHomeMembers(homeId);
        return ResponseEntity.ok(ApiResponse.success(members));
    }

    @PutMapping("/{homeId}/members/{userId}/role")
    @PreAuthorize("@homeSecurity.isOwner(#homeId)")
    @Operation(summary = "Update member role (OWNER only)")
    public ResponseEntity<ApiResponse<HomeMemberDto>> updateMemberRole(
            @PathVariable UUID homeId,
            @PathVariable UUID userId,
            @Valid @RequestBody UpdateMemberRoleRequest request) {
        HomeMemberDto updated = homeService.updateMemberRole(homeId, userId, request);
        return ResponseEntity.ok(ApiResponse.success("Member role updated", updated));
    }

    @DeleteMapping("/{homeId}/members/{userId}")
    @PreAuthorize("@homeSecurity.canRemoveMember(#homeId, #userId)")
    @Operation(summary = "Remove a member or leave home")
    public ResponseEntity<ApiResponse<Void>> removeMember(
            @PathVariable UUID homeId,
            @PathVariable UUID userId) {
        homeService.removeMember(homeId, userId);
        return ResponseEntity.ok(ApiResponse.success("Member removed", null));
    }
}
