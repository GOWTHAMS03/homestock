package com.homestock.modules.smartshopping.entity;

import com.homestock.core.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

/**
 * Mapping between external provider product listings and internal canonical products.
 */
@Entity
@Table(name = "provider_products", indexes = {
        @Index(name = "idx_pp_provider_product", columnList = "provider_name, provider_product_id"),
        @Index(name = "idx_pp_canonical_product", columnList = "product_id")
}, uniqueConstraints = {
        @UniqueConstraint(name = "uq_provider_product", columnNames = {"provider_name", "provider_product_id"})
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProviderProduct extends BaseEntity {

    @Column(name = "provider_name", nullable = false, length = 50)
    private String providerName;

    @Column(name = "provider_product_id", nullable = false, length = 200)
    private String providerProductId;

    @Column(name = "product_id")
    private UUID productId;

    @Column(name = "title", nullable = false, length = 300)
    private String title;

    @Column(name = "brand", length = 150)
    private String brand;

    @Column(name = "variant", length = 100)
    private String variant;

    @Column(name = "package_size", length = 50)
    private String packageSize;

    @Column(name = "unit", length = 30)
    private String unit;

    @Column(name = "url", length = 1000)
    private String url;

    @Column(name = "image_url", length = 500)
    private String imageUrl;

    @Column(name = "last_synced_at")
    private Instant lastSyncedAt;
}
