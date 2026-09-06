package com.homestock.modules.home.dto;

import com.homestock.modules.home.entity.Home;
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
public class HomeDto {
    private UUID id;
    private String name;
    private String inviteCode;
    private UUID createdById;
    private String createdByName;
    private HomeRole currentUserRole;
    private int memberCount;
    private Instant createdAt;

    public static HomeDto fromEntity(Home home, HomeRole userRole, int memberCount) {
        if (home == null) return null;
        return HomeDto.builder()
                .id(home.getId())
                .name(home.getName())
                .inviteCode(home.getInviteCode())
                .createdById(home.getCreatedBy().getId())
                .createdByName(home.getCreatedBy().getFullName())
                .currentUserRole(userRole)
                .memberCount(memberCount)
                .createdAt(home.getCreatedAt())
                .build();
    }
}
