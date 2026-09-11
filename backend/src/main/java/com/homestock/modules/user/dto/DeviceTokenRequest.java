package com.homestock.modules.user.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class DeviceTokenRequest {
    @NotBlank(message = "Token is required")
    @JsonAlias({"deviceToken", "device_token", "fcmToken", "fcm_token"})
    private String token;

    @NotBlank(message = "Device type is required")
    @JsonAlias({"platform"})
    private String deviceType; // ANDROID, IOS, WEB
}
