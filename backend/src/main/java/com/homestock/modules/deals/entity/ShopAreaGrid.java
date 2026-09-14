package com.homestock.modules.deals.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Metadata record representing a geographic grid area and its synchronization status.
 * Coordinates nearby users into shared geographic buckets (~2.5km) to eliminate duplicate OSM queries.
 */
@Entity
@Table(name = "shop_area_grids", indexes = {
        @Index(name = "idx_sag_sync_status", columnList = "sync_status"),
        @Index(name = "idx_sag_last_sync", columnList = "last_sync_at"),
        @Index(name = "idx_sag_coords", columnList = "center_lat, center_lon")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopAreaGrid {

    @Id
    @Column(name = "grid_key", length = 60)
    private String gridKey;

    @Column(name = "geohash", length = 12)
    private String geohash;

    @Column(name = "center_lat", nullable = false, precision = 10, scale = 7)
    private BigDecimal centerLat;

    @Column(name = "center_lon", nullable = false, precision = 10, scale = 7)
    private BigDecimal centerLon;

    @Column(name = "radius_meters", nullable = false)
    private Integer radiusMeters;

    @Column(name = "last_sync_at")
    private Instant lastSyncAt;

    @Builder.Default
    @Column(name = "shop_count", nullable = false)
    private Integer shopCount = 0;

    @Builder.Default
    @Column(name = "sync_status", nullable = false, length = 30)
    private String syncStatus = "PENDING"; // PENDING, SYNCING, COMPLETED, FAILED

    @Column(name = "failure_reason", length = 255)
    private String failureReason;

    @Builder.Default
    @Column(name = "sync_attempts", nullable = false)
    private Integer syncAttempts = 0;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public boolean isStale(long maxAgeHours) {
        if (lastSyncAt == null) return true;
        return Instant.now().isAfter(lastSyncAt.plus(java.time.Duration.ofHours(maxAgeHours)));
    }
}
