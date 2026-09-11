package com.homestock.modules.away.dto;

import com.homestock.modules.away.entity.UserActivityType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserActivityHeartbeatRequest {
    private UUID homeId;
    @Builder.Default
    private UserActivityType activityType = UserActivityType.APP_OPEN;
    private String metadata;
}
