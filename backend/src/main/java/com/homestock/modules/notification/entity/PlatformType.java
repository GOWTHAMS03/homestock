package com.homestock.modules.notification.entity;

public enum PlatformType {
    ANDROID,
    IOS,
    WEB;

    public static PlatformType fromString(String value) {
        if (value == null) return ANDROID;
        try {
            return PlatformType.valueOf(value.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return ANDROID;
        }
    }
}

