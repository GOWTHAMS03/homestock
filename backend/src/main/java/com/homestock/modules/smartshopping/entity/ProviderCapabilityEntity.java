package com.homestock.modules.smartshopping.entity;

import com.homestock.core.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

/**
 * Persisted provider capability declaration.
 */
@Entity
@Table(name = "provider_capabilities", indexes = {
        @Index(name = "idx_pc_provider", columnList = "provider_name")
}, uniqueConstraints = {
        @UniqueConstraint(name = "uq_provider_capability", columnNames = {"provider_name", "capability"})
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProviderCapabilityEntity extends BaseEntity {

    @Column(name = "provider_name", nullable = false, length = 50)
    private String providerName;

    @Column(name = "capability", nullable = false, length = 50)
    private String capability;
}
