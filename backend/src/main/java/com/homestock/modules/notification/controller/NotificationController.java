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

    @PostMapping("/device-token")
    @Operation(summary = "Register or update FCM device token for authenticated user")
    public ResponseEntity<ApiResponse<Void>> registerDeviceToken(@Valid @RequestBody DeviceTokenRequest request) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        deviceTokenService.registerDeviceToken(currentUser, request);
        return ResponseEntity.ok(ApiResponse.success("Device token registered successfully", null));
    }

    @DeleteMapping("/device-token")
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
}
