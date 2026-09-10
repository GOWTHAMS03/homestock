package com.homestock.modules.notification.service;

import com.homestock.core.common.PagedResponse;
import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.notification.dto.NotificationDto;
import com.homestock.modules.notification.entity.Notification;
import com.homestock.modules.notification.entity.NotificationType;
import com.homestock.modules.notification.repository.NotificationRepository;
import com.homestock.modules.user.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final NotificationEngine notificationEngine;

    @Transactional(readOnly = true)
    public PagedResponse<NotificationDto> getNotificationsForUser(UUID userId, Pageable pageable) {
        Page<Notification> notifPage = notificationRepository.findAllByUserIdOrderByCreatedAtDesc(userId, pageable);
        return PagedResponse.from(notifPage.map(NotificationDto::fromEntity));
    }

    @Transactional(readOnly = true)
    public long getUnreadCountForUser(UUID userId) {
        return notificationRepository.countByUserIdAndIsReadFalse(userId);
    }

    @Transactional
    public void markAsRead(UUID notificationId, UUID userId) {
        Notification notification = notificationRepository.findByIdAndUserId(notificationId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found"));

        notification.setIsRead(true);
        notification.setReadAt(Instant.now());
        notificationRepository.save(notification);
    }

    @Transactional
    public void markAllAsRead(UUID userId) {
        notificationRepository.markAllReadForUser(userId, Instant.now());
    }

    @Transactional
    public void deleteNotification(UUID notificationId, UUID userId) {
        Notification notification = notificationRepository.findByIdAndUserId(notificationId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found"));
        notificationRepository.delete(notification);
    }

    /**
     * Backward-compatible delegation to NotificationEngine.
     */
    @Transactional
    public void notifyHomeMembers(Home home, User excludedUser, NotificationType type, String title, String body, String payloadJson) {
        Map<String, String> data = null;
        if (payloadJson != null && !payloadJson.isBlank()) {
            data = Map.of("payload", payloadJson, "type", type.name());
        }
        notificationEngine.dispatchHomeNotification(
                home, excludedUser, type, title, body, null, null, null, null, data
        );
    }

    /**
     * Backward-compatible delegation to NotificationEngine.
     */
    @Transactional
    public void notifyUser(Home home, User user, NotificationType type, String title, String body, String payloadJson) {
        Map<String, String> data = null;
        if (payloadJson != null && !payloadJson.isBlank()) {
            data = Map.of("payload", payloadJson, "type", type.name());
        }
        notificationEngine.dispatchUserNotification(
                home, user, type, title, body, null, data
        );
    }
}
