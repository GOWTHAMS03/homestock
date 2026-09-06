package com.homestock.modules.home.dto;

import com.homestock.modules.home.entity.HomeMember;
import com.homestock.modules.home.entity.HomeRole;
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
public class HomeMemberDto {
    private UUID id;
    private UUID userId;
    private String fullName;
    private String email;
    private String avatarUrl;
    private HomeRole role;
    private Instant joinedAt;

    public static HomeMemberDto fromEntity(HomeMember member) {
        if (member == null) return null;
        return HomeMemberDto.builder()
                .id(member.getId())
                .userId(member.getUser().getId())
                .fullName(member.getUser().getFullName())
                .email(member.getUser().getEmail())
                .avatarUrl(member.getUser().getAvatarUrl())
                .role(member.getRole())
                .joinedAt(member.getJoinedAt())
                .build();
    }
}
