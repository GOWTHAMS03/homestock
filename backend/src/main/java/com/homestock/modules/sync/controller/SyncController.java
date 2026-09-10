package com.homestock.modules.sync.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.sync.dto.SyncPullResponse;
import com.homestock.modules.sync.dto.SyncPushResponse;
import com.homestock.modules.sync.dto.SyncRequest;
import com.homestock.modules.sync.service.SyncService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/sync")
@RequiredArgsConstructor
@Tag(name = "Offline Sync", description = "Endpoints for bidirectional offline-first data synchronization")
public class SyncController {

    private final SyncService syncService;

    @PostMapping
    @PreAuthorize("@homeSecurity.isMember(#request.homeId)")
    @Operation(summary = "Batch push offline operations idempotently")
    public ResponseEntity<ApiResponse<SyncPushResponse>> pushOperations(
            @Valid @RequestBody SyncRequest request) {
        SyncPushResponse response = syncService.pushOperations(request);
        return ResponseEntity.ok(ApiResponse.success("Sync operations processed", response));
    }

    @GetMapping
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Incremental pull server changes since timestamp or cursor version")
    public ResponseEntity<ApiResponse<SyncPullResponse>> pullChanges(
            @RequestParam UUID homeId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant since,
            @RequestParam(required = false) Long sinceVersion,
            @RequestParam(required = false, defaultValue = "500") Integer limit) {
        Instant effectiveSince = since != null ? since : Instant.EPOCH;
        SyncPullResponse response = syncService.pullChanges(homeId, effectiveSince, sinceVersion, limit);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
