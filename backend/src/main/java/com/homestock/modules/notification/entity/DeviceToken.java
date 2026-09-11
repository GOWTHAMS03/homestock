package com.homestock.modules.notification.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Table(name = "device_tokens", indexes = {
    @Index(name = "idx_device_tokens_user", columnList = "user_id"),
    @Index(name = "idx_device_tokens_token", columnList = "device_token", unique = true)
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeviceToken extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "device_token", nullable = false, length = 500, unique = true)
    private String deviceToken;

    @Enumerated(EnumType.STRING)
    @Column(name = "platform", nullable = false, length = 20)
    @Builder.Default
    private PlatformType platform = PlatformType.ANDROID;

    @Column(name = "device_name", length = 120)
    private String deviceName;

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "token", length = 512)
    private String token;

    @Column(name = "device_type", length = 20)
    private String deviceType;

    @Column(name = "last_used_at")
    private Instant lastUsedAt;

    @Column(name = "last_seen_at")
    private Instant lastSeenAt;

    @PrePersist
    @PreUpdate
    public void syncLegacyFields() {
        if (this.token == null || this.token.isBlank()) {
            this.token = this.deviceToken;
        }
        if (this.deviceType == null || this.deviceType.isBlank()) {
            this.deviceType = this.platform != null ? this.platform.name() : "ANDROID";
        }
        if (this.lastUsedAt == null) {
            this.lastUsedAt = this.lastSeenAt != null ? this.lastSeenAt : Instant.now();
        }
    }
}

