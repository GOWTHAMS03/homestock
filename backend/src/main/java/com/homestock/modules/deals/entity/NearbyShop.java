package com.homestock.modules.deals.entity;

import com.homestock.core.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * Nearby physical retail store entity (supermarkets, grocery stores, provision stores, etc.)
 */
@Entity
@Table(name = "nearby_shops", indexes = {
        @Index(name = "idx_ns_coords", columnList = "latitude, longitude"),
        @Index(name = "idx_ns_city", columnList = "city"),
        @Index(name = "idx_ns_postal_code", columnList = "postal_code"),
        @Index(name = "idx_ns_shop_type", columnList = "shop_type"),
        @Index(name = "idx_ns_osmid", columnList = "osm_id")
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

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;
}
