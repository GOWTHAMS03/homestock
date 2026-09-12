package com.homestock.modules.home.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.home.dto.CreateRoomRequest;
import com.homestock.modules.home.dto.JoinRoomRequest;
import com.homestock.modules.home.dto.RoomDto;
import com.homestock.modules.home.dto.RoomMemberDto;
import com.homestock.modules.home.service.RoomService;
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
@RequestMapping("/api/v1/rooms")
@RequiredArgsConstructor
@Tag(name = "Rooms & Household Members", description = "Endpoints for room management, idempotent joining, and member access")
public class RoomController {

    private final RoomService roomService;

    @GetMapping
    @Operation(summary = "List all household rooms the authenticated user actively belongs to")
    public ResponseEntity<ApiResponse<List<RoomDto>>> getMyRooms() {
        List<RoomDto> rooms = roomService.getCurrentUserRooms();
        return ResponseEntity.ok(ApiResponse.success(rooms));
    }

    @PostMapping
    @Operation(summary = "Create a new household room and become OWNER")
    public ResponseEntity<ApiResponse<RoomDto>> createRoom(@Valid @RequestBody CreateRoomRequest request) {
        RoomDto room = roomService.createRoom(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Room created successfully", room));
    }

    @PostMapping("/join")
    @Operation(summary = "Join an existing household room idempotently using room code")
    public ResponseEntity<ApiResponse<RoomDto>> joinRoom(@Valid @RequestBody JoinRoomRequest request) {
        RoomDto room = roomService.joinRoom(request);
        return ResponseEntity.ok(ApiResponse.success("Joined room successfully", room));
    }

    @GetMapping("/{roomId}")
    @PreAuthorize("@roomSecurity.isMember(#roomId)")
    @Operation(summary = "Get room details by ID")
    public ResponseEntity<ApiResponse<RoomDto>> getRoom(@PathVariable UUID roomId) {
        RoomDto room = roomService.getRoomById(roomId);
        return ResponseEntity.ok(ApiResponse.success(room));
    }

    @GetMapping("/{roomId}/members")
    @PreAuthorize("@roomSecurity.isMember(#roomId)")
    @Operation(summary = "List all active members of a room")
    public ResponseEntity<ApiResponse<List<RoomMemberDto>>> getMembers(@PathVariable UUID roomId) {
        List<RoomMemberDto> members = roomService.getRoomMembers(roomId);
        return ResponseEntity.ok(ApiResponse.success(members));
    }

    @DeleteMapping("/{roomId}/members/{userId}")
    @PreAuthorize("@roomSecurity.canRemoveMember(#roomId, #userId)")
    @Operation(summary = "Remove a member or leave room (soft removal)")
    public ResponseEntity<ApiResponse<Void>> removeMember(
            @PathVariable UUID roomId,
            @PathVariable UUID userId) {
        roomService.removeMember(roomId, userId);
        return ResponseEntity.ok(ApiResponse.success("Member removed successfully", null));
    }
}
