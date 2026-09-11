package com.homestock.modules.notification.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
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
    @JsonAlias({"token", "fcmToken", "fcm_token", "registrationToken"})
    private String deviceToken;

    @Builder.Default
    @JsonAlias({"deviceType", "device_type"})
    private PlatformType platform = PlatformType.ANDROID;

    @JsonAlias({"deviceModel", "device_model", "device_name"})
    private String deviceName;

    public void setToken(String token) {
        if (this.deviceToken == null || this.deviceToken.isBlank()) {
            this.deviceToken = token;
        }
    }

    public void setDeviceModel(String deviceModel) {
        if (this.deviceName == null || this.deviceName.isBlank()) {
            this.deviceName = deviceModel;
        }
    }
}

