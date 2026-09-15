package com.homestock.modules.shop.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Anonymized, privacy-safe demand event recording customer shopping signals.
 * ZERO customer personal identity (no user ID, name, email, or household) is stored.
 */
@Entity
@Table(name = "customer_demand_events", indexes = {
        @Index(name = "idx_cde_coords_created", columnList = "created_at, latitude, longitude"),
        @Index(name = "idx_cde_norm_created", columnList = "normalized_query, created_at"),
        @Index(name = "idx_cde_product_created", columnList = "product_id, created_at"),
        @Index(name = "idx_cde_type_created", columnList = "event_type, created_at")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerDemandEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(name = "event_type", nullable = false, length = 30)
    private DemandEventType eventType;

    @Column(name = "query_text", nullable = false, length = 255)
    private String queryText;

    @Column(name = "normalized_query", nullable = false, length = 255)
    private String normalizedQuery;

    @Column(name = "product_id")
    private UUID productId;

    @Column(name = "category_name", length = 100)
    private String categoryName;

    @Column(name = "latitude", precision = 10, scale = 7, nullable = false)
    private BigDecimal latitude;

    @Column(name = "longitude", precision = 10, scale = 7, nullable = false)
    private BigDecimal longitude;

    @Builder.Default
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}
