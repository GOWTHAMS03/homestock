package com.homestock.modules.notification.entity;

public enum PlatformType {
    ANDROID,
    IOS,
    WEB;

    public static PlatformType fromString(String type) {
        if (type == null) return ANDROID;
        try {
            return PlatformType.valueOf(type.toUpperCase().trim());
        } catch (Exception e) {
            return ANDROID;
        }
    }
}
