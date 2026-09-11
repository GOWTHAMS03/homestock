package com.homestock.modules.notification.dto;

import com.homestock.modules.notification.entity.NotificationUserAction;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationActionRequest {

    @NotNull(message = "Action type is required")
    private NotificationUserAction actionType;

    private Map<String, String> metadata;
}
