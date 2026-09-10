package com.homestock.modules.notification.dto;

import com.homestock.modules.notification.entity.PlatformType;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeviceTokenRequest {

    @NotBlank(message = "Device token is required")
    private String deviceToken;

    @Builder.Default
    private PlatformType platform = PlatformType.ANDROID;

    private String deviceName;
}

