package com.homestock.modules.user.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class DeviceTokenRequest {
    @NotBlank(message = "Token is required")
    private String token;

    @NotBlank(message = "Device type is required")
    private String deviceType; // ANDROID, IOS, WEB
}
