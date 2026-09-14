package com.homestock.modules.deals.entity;

import com.homestock.core.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Nearby physical retail store entity (supermarkets, grocery stores, provision stores, etc.)
 */
@Entity
@Table(name = "nearby_shops", indexes = {
        @Index(name = "idx_ns_coords", columnList = "latitude, longitude"),
        @Index(name = "idx_ns_city", columnList = "city"),
        @Index(name = "idx_ns_postal_code", columnList = "postal_code"),
        @Index(name = "idx_ns_shop_type", columnList = "shop_type"),
        @Index(name = "idx_ns_osmid", columnList = "osm_id"),
        @Index(name = "idx_ns_active", columnList = "active"),
        @Index(name = "idx_ns_normalized_name", columnList = "normalized_name"),
        @Index(name = "idx_ns_confidence", columnList = "confidence_score")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NearbyShop extends BaseEntity {

    @Column(name = "osm_id", length = 60)
    private String osmId;

    @Column(name = "name", nullable = false, length = 150)
    private String name;

    @Column(name = "normalized_name", length = 150)
    private String normalizedName;

    @Builder.Default
    @Column(name = "shop_type", nullable = false, length = 50)
    private String shopType = "SUPERMARKET"; // SUPERMARKET, GROCERY, HYPERMARKET, PROVISION, WHOLESALE, DEPARTMENT

    @Column(name = "address", length = 300)
    private String address;

    @Column(name = "area", length = 100)
    private String area;

    @Column(name = "city", nullable = false, length = 100)
    private String city;

    @Builder.Default
    @Column(name = "state", length = 100)
    private String state = "Tamil Nadu";

    @Column(name = "postal_code", length = 20)
    private String postalCode;

    @Column(name = "latitude", nullable = false, precision = 10, scale = 7)
    private BigDecimal latitude;

    @Column(name = "longitude", nullable = false, precision = 10, scale = 7)
    private BigDecimal longitude;

    @Column(name = "geohash", length = 12)
    private String geohash;

    @Column(name = "phone", length = 50)
    private String phone;

    @Builder.Default
    @Column(name = "rating", precision = 3, scale = 2)
    private BigDecimal rating = BigDecimal.valueOf(4.2);

    @Builder.Default
    @Column(name = "review_count")
    private Integer reviewCount = 0;

    @Builder.Default
    @Column(name = "opening_hours", length = 100)
    private String openingHours = "8:00 AM - 10:00 PM";

    @Builder.Default
    @Column(name = "is_open", nullable = false)
    private Boolean isOpen = true;

    @Builder.Default
    @Column(name = "is_verified", nullable = false)
    private Boolean isVerified = true;

    @Builder.Default
    @Column(name = "source", nullable = false, length = 50)
    private String source = "OSM"; // OSM, USER, FALLBACK

    @Column(name = "source_id", length = 100)
    private String sourceId;

    @Column(name = "category", length = 50)
    private String category;

    @Builder.Default
    @Column(name = "confidence_score", nullable = false)
    private Integer confidenceScore = 70; // OSM=70, USER=50, etc.

    @Column(name = "last_osm_sync_at")
    private Instant lastOsmSyncAt;

    @Column(name = "last_verified_at")
    private Instant lastVerifiedAt;

    @Builder.Default
    @Column(name = "active", nullable = false)
    private Boolean active = true;

    @Builder.Default
    @Column(name = "user_report_count", nullable = false)
    private Integer userReportCount = 0;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;
}
