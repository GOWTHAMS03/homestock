package com.homestock.modules.notification.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.core.common.PagedResponse;
import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.core.util.SecurityUtils;
import com.homestock.modules.notification.dto.DeviceTokenRequest;
import com.homestock.modules.notification.dto.NotificationDto;
import com.homestock.modules.notification.dto.NotificationPreferenceDto;
import com.homestock.modules.notification.entity.NotificationPreference;
import com.homestock.modules.notification.service.DeviceTokenService;
import com.homestock.modules.notification.service.NotificationAnalyticsService;
import com.homestock.modules.notification.service.NotificationPreferenceService;
import com.homestock.modules.notification.service.NotificationService;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
@Tag(name = "Notifications", description = "Endpoints for user alerts, preferences, device tokens, and low-stock updates")
public class NotificationController {

    private final NotificationService notificationService;
    private final NotificationPreferenceService preferenceService;
    private final DeviceTokenService deviceTokenService;
    private final UserRepository userRepository;
    private final NotificationAnalyticsService analyticsService;
    private final com.homestock.modules.notification.provider.FirebaseNotificationProvider firebaseNotificationProvider;

    @GetMapping
    @Operation(summary = "Get user's notifications with pagination")
    public ResponseEntity<ApiResponse<PagedResponse<NotificationDto>>> getNotifications(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        Pageable pageable = PageRequest.of(page, size);
        PagedResponse<NotificationDto> response = notificationService.getNotificationsForUser(currentUserId, pageable);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping("/unread-count")
    @Operation(summary = "Get total unread notifications count for current user")
    public ResponseEntity<ApiResponse<Map<String, Long>>> getUnreadCount() {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        long count = notificationService.getUnreadCountForUser(currentUserId);
        return ResponseEntity.ok(ApiResponse.success(Map.of("unreadCount", count)));
    }

    @PatchMapping("/{id}/read")
    @Operation(summary = "Mark a notification as read")
    public ResponseEntity<ApiResponse<Void>> markAsRead(@PathVariable UUID id) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        notificationService.markAsRead(id, currentUserId);
        return ResponseEntity.ok(ApiResponse.success("Notification marked read", null));
    }

    @PostMapping("/{id}/action")
    @Operation(summary = "Record action taken on notification by user (e.g. Added to List, Viewed Deal)")
    public ResponseEntity<ApiResponse<Void>> recordAction(
            @PathVariable UUID id,
            @Valid @RequestBody com.homestock.modules.notification.dto.NotificationActionRequest request) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        analyticsService.recordAction(id, currentUserId, request.getActionType());
        return ResponseEntity.ok(ApiResponse.success("Action recorded successfully", null));
    }

    @PostMapping("/{id}/dismiss")
    @Operation(summary = "Record notification dismissal for fatigue and relevance learning")
    public ResponseEntity<ApiResponse<Void>> recordDismiss(@PathVariable UUID id) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        analyticsService.recordDismissal(id, currentUserId);
        return ResponseEntity.ok(ApiResponse.success("Dismissal recorded", null));
    }

    @GetMapping("/insights")
    @Operation(summary = "Get high-value household restock and savings insights")
    public ResponseEntity<ApiResponse<List<com.homestock.modules.notification.dto.SmartInsightDto>>> getSmartInsights(
            @RequestParam(required = false) UUID homeId) {
        UUID effectiveHomeId = homeId != null ? homeId : SecurityUtils.getCurrentUserId();
        List<com.homestock.modules.notification.dto.SmartInsightDto> insights = analyticsService.getSmartInsights(effectiveHomeId);
        return ResponseEntity.ok(ApiResponse.success(insights));
    }

    @PostMapping("/read-all")
    @Operation(summary = "Mark all notifications as read for current user")
    public ResponseEntity<ApiResponse<Void>> markAllAsRead() {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        notificationService.markAllAsRead(currentUserId);
        return ResponseEntity.ok(ApiResponse.success("All notifications marked as read", null));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a notification")
    public ResponseEntity<ApiResponse<Void>> deleteNotification(@PathVariable UUID id) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        notificationService.deleteNotification(id, currentUserId);
        return ResponseEntity.ok(ApiResponse.success("Notification deleted", null));
    }

    @DeleteMapping
    @Operation(summary = "Clear all notifications for current user")
    public ResponseEntity<ApiResponse<Void>> deleteAllNotifications() {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        notificationService.deleteAllNotifications(currentUserId);
        return ResponseEntity.ok(ApiResponse.success("All notifications deleted", null));
    }

    // ==========================================
    // Notification Preferences Endpoints
    // ==========================================

    @GetMapping("/preferences")
    @Operation(summary = "Get current user's notification preferences")
    public ResponseEntity<ApiResponse<NotificationPreferenceDto>> getPreferences() {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        NotificationPreference pref = preferenceService.getOrCreatePreferences(currentUser);
        return ResponseEntity.ok(ApiResponse.success(NotificationPreferenceDto.fromEntity(pref)));
    }

    @PutMapping("/preferences")
    @Operation(summary = "Update current user's notification preferences")
    public ResponseEntity<ApiResponse<NotificationPreferenceDto>> updatePreferences(
            @RequestBody NotificationPreferenceDto dto) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        NotificationPreferenceDto updated = preferenceService.updatePreferences(currentUser, dto);
        return ResponseEntity.ok(ApiResponse.success("Preferences updated", updated));
    }

    // ==========================================
    // FCM Device Token Endpoints
    // ==========================================

    @PostMapping({"/device-token", "/device-tokens"})
    @Operation(summary = "Register or update FCM device token for authenticated user")
    public ResponseEntity<ApiResponse<Void>> registerDeviceToken(@Valid @RequestBody DeviceTokenRequest request) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        deviceTokenService.registerDeviceToken(currentUser, request);
        return ResponseEntity.ok(ApiResponse.success("Device token registered successfully", null));
    }

    @DeleteMapping({"/device-token", "/device-tokens"})
    @Operation(summary = "Deactivate FCM device token on logout")
    public ResponseEntity<ApiResponse<Void>> deactivateDeviceToken(
            @RequestParam(required = false) String token,
            @RequestBody(required = false) DeviceTokenRequest request) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        String tokenToDeactivate = token;
        if ((tokenToDeactivate == null || tokenToDeactivate.isBlank()) && request != null) {
            tokenToDeactivate = request.getDeviceToken();
        }
        deviceTokenService.deactivateDeviceToken(currentUserId, tokenToDeactivate);
        return ResponseEntity.ok(ApiResponse.success("Device token deactivated", null));
    }

    @PostMapping("/test")
    @Operation(summary = "Send a test Firebase push notification to current user's registered devices")
    public ResponseEntity<ApiResponse<Map<String, Object>>> sendTestNotification(
            @RequestParam(defaultValue = "Test Alert") String title,
            @RequestParam(defaultValue = "HomeStock Firebase push notifications are working perfectly! \uD83C\uDF89") String message,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String entityId) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        List<com.homestock.modules.notification.entity.DeviceToken> tokens = deviceTokenService.getActiveTokensForUser(currentUserId);
        boolean isConfigured = firebaseNotificationProvider.isConfigured();

        if (tokens.isEmpty()) {
            return ResponseEntity.ok(ApiResponse.success("No active device tokens found for user. Please register a device token first.", Map.of(
                    "firebaseConfigured", isConfigured,
                    "tokensCount", 0,
                    "status", "NO_TOKENS"
            )));
        }

        com.homestock.modules.notification.entity.NotificationType resolvedType =
                com.homestock.modules.notification.entity.NotificationType.SYSTEM;
        if (type != null && !type.isBlank()) {
            try {
                resolvedType = com.homestock.modules.notification.entity.NotificationType.valueOf(type.toUpperCase());
            } catch (Exception ignored) {}
        } else {
            String lower = title.toLowerCase();
            if (lower.contains("expir")) {
                resolvedType = com.homestock.modules.notification.entity.NotificationType.EXPIRY_REMINDER;
            } else if (lower.contains("shopping")) {
                resolvedType = com.homestock.modules.notification.entity.NotificationType.SHOPPING_LIST_UPDATE;
            } else if (lower.contains("low stock") || lower.contains("out of stock") || lower.contains("stock")) {
                resolvedType = com.homestock.modules.notification.entity.NotificationType.LOW_STOCK;
            }
        }

        Map<String, String> data = new java.util.HashMap<>();
        data.put("action", "TEST");
        data.put("type", resolvedType.name());
        data.put("timestamp", java.time.Instant.now().toString());
        if (entityId != null && !entityId.isBlank()) {
            data.put("entityId", entityId);
            data.put("itemId", entityId);
        }

        firebaseNotificationProvider.sendPushNotification(
                tokens,
                resolvedType,
                com.homestock.modules.notification.entity.NotificationPriority.HIGH,
                title,
                message,
                data
        );

        return ResponseEntity.ok(ApiResponse.success("Test notification dispatched to " + tokens.size() + " device(s)", Map.of(
                "firebaseConfigured", isConfigured,
                "tokensCount", tokens.size(),
                "status", "SENT"
        )));
    }
}
