package com.homestock.modules.home.dto;

import com.homestock.modules.home.entity.RoomMember;
import com.homestock.modules.home.entity.RoomMemberRole;
import com.homestock.modules.home.entity.RoomMemberStatus;
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
public class RoomMemberDto {
    private UUID id;
    private UUID roomId;
    private UUID userId;
    private String displayName;
    private String username;
    private String email;
    private String avatarUrl;
    private RoomMemberRole role;
    private RoomMemberStatus status;
    private Instant joinedAt;
    private Instant lastSeenAt;

    public static RoomMemberDto fromEntity(RoomMember member) {
        if (member == null) return null;
        return RoomMemberDto.builder()
                .id(member.getId())
                .roomId(member.getRoom().getId())
                .userId(member.getUser().getId())
                .displayName(member.getUser().getDisplayName())
                .username(member.getUser().getUsername())
                .email(member.getUser().getEmail())
                .avatarUrl(member.getUser().getAvatarUrl())
                .role(member.getRole())
                .status(member.getStatus())
                .joinedAt(member.getJoinedAt())
                .lastSeenAt(member.getLastSeenAt())
                .build();
    }
}
