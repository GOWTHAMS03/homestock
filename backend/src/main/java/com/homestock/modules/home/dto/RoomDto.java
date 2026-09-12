package com.homestock.modules.home.dto;

import com.homestock.modules.home.entity.Room;
import com.homestock.modules.home.entity.RoomMemberRole;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RoomDto {
    private UUID id;
    private String roomCode;
    private String name;
    private UUID ownerUserId;
    private String ownerName;
    private String status;
    private RoomMemberRole currentUserRole;
    private int memberCount;
    private Instant createdAt;

    public static RoomDto fromEntity(Room room, RoomMemberRole userRole, int memberCount) {
        if (room == null) return null;
        return RoomDto.builder()
                .id(room.getId())
                .roomCode(room.getRoomCode())
                .name(room.getName())
                .ownerUserId(room.getOwner().getId())
                .ownerName(room.getOwner().getDisplayName())
                .status(room.getStatus())
                .currentUserRole(userRole)
                .memberCount(memberCount)
                .createdAt(room.getCreatedAt())
                .build();
    }
}
