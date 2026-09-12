package com.homestock.modules.user.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.homestock.core.common.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.*;

@Entity
@Table(name = "users")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class User extends BaseEntity {

    @Column(name = "email", unique = true, nullable = false)
    private String email;

    @JsonIgnore
    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Column(name = "full_name", nullable = false, length = 120)
    private String fullName;

    @Column(name = "display_name", length = 120)
    private String displayName;

    @Column(name = "username", unique = true, length = 60)
    private String username;

    @Column(name = "avatar_url", length = 512)
    private String avatarUrl;

    @Column(name = "phone_number", length = 25)
    private String phoneNumber;

    @Builder.Default
    @Column(name = "status", nullable = false, length = 20)
    private String status = "ACTIVE";

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "last_login_at")
    private java.time.Instant lastLoginAt;

    @Column(name = "deleted_at")
    private java.time.Instant deletedAt;

    public String getDisplayName() {
        return displayName != null && !displayName.isBlank() ? displayName : fullName;
    }

    public boolean isDeleted() {
        return deletedAt != null || "DELETED".equalsIgnoreCase(status);
    }

    public boolean isAccountActive() {
        return !isDeleted() && !"DISABLED".equalsIgnoreCase(status) && Boolean.TRUE.equals(isActive);
    }
}
