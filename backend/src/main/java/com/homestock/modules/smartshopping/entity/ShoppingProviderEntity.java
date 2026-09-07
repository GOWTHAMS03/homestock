package com.homestock.modules.smartshopping.entity;

import com.homestock.core.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

/**
 * Registered shopping provider (online or local).
 * Stores metadata and provider configuration.
 */
@Entity
@Table(name = "shopping_providers", indexes = {
        @Index(name = "idx_sp_name", columnList = "name", unique = true),
        @Index(name = "idx_sp_enabled", columnList = "is_enabled")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShoppingProviderEntity extends BaseEntity {

    @Column(name = "name", nullable = false, unique = true, length = 50)
    private String name;

    @Column(name = "display_name", nullable = false, length = 100)
    private String displayName;

    @Column(name = "logo_url", length = 500)
    private String logoUrl;

    @Builder.Default
    @Column(name = "is_enabled", nullable = false)
    private boolean enabled = true;

    @Column(name = "provider_type", nullable = false, length = 20)
    private String providerType; // ONLINE or LOCAL

    @Column(name = "config_json", columnDefinition = "TEXT")
    private String configJson;
}
