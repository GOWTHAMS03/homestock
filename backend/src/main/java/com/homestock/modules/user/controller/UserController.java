package com.homestock.modules.user.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.user.dto.DeviceTokenRequest;
import com.homestock.modules.user.dto.UpdateProfileRequest;
import com.homestock.modules.user.dto.UserDto;
import com.homestock.modules.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Tag(name = "User Profile", description = "Endpoints for managing user profile and device tokens")
public class UserController {

    private final UserService userService;

    @GetMapping("/me")
    @Operation(summary = "Get current authenticated user's profile")
    public ResponseEntity<ApiResponse<UserDto>> getCurrentUser() {
        UserDto profile = userService.getCurrentUserProfile();
        return ResponseEntity.ok(ApiResponse.success(profile));
    }

    @PutMapping("/me")
    @Operation(summary = "Update current authenticated user's profile")
    public ResponseEntity<ApiResponse<UserDto>> updateProfile(@Valid @RequestBody UpdateProfileRequest request) {
        UserDto updated = userService.updateProfile(request);
        return ResponseEntity.ok(ApiResponse.success("Profile updated successfully", updated));
    }

    @PostMapping("/me/device-tokens")
    @Operation(summary = "Register FCM device token for push notifications")
    public ResponseEntity<ApiResponse<Void>> registerDeviceToken(@Valid @RequestBody DeviceTokenRequest request) {
        userService.registerDeviceToken(request);
        return ResponseEntity.ok(ApiResponse.success("Device token registered", null));
    }
}
