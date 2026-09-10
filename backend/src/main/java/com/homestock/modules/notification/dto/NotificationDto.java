package com.homestock.modules.notification.dto;

import com.homestock.modules.notification.entity.Notification;
import com.homestock.modules.notification.entity.NotificationPriority;
import com.homestock.modules.notification.entity.NotificationType;
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
public class NotificationDto {
    private UUID id;
    private UUID homeId;
    private NotificationType type;
    private NotificationPriority priority;
    private String title;
    private String body;
    private String payloadJson;
    private Boolean isRead;
    private Instant createdAt;
    private Instant readAt;

    public static NotificationDto fromEntity(Notification notification) {
        if (notification == null) return null;
        return NotificationDto.builder()
                .id(notification.getId())
                .homeId(notification.getHome() != null ? notification.getHome().getId() : null)
                .type(notification.getType())
                .priority(notification.getPriority())
                .title(notification.getTitle())
                .body(notification.getBody())
                .payloadJson(notification.getPayloadJson())
                .isRead(notification.getIsRead())
                .createdAt(notification.getCreatedAt())
                .readAt(notification.getReadAt())
                .build();
    }
}
