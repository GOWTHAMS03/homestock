package com.homestock.modules.deals.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * User-isolated, private shopping location context.
 * NEVER synced across room or family profiles.
 */
@Entity
@Table(name = "user_location_preferences", indexes = {
        @Index(name = "idx_ulp_user_id", columnList = "user_id")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserLocationPreference extends BaseEntity {

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "latitude", precision = 10, scale = 7)
    private BigDecimal latitude;

    @Column(name = "longitude", precision = 10, scale = 7)
    private BigDecimal longitude;

    @Column(name = "approximate_area", length = 150)
    private String approximateArea;

    @Column(name = "city", length = 100)
    private String city;

    @Column(name = "postal_code", length = 20)
    private String postalCode;

    @Column(name = "geohash", length = 12)
    private String geohash;

    @Builder.Default
    @Column(name = "is_manual", nullable = false)
    private Boolean isManual = false;

    @Builder.Default
    @Column(name = "preferred_radius_km", precision = 5, scale = 2, nullable = false)
    private BigDecimal preferredRadiusKm = BigDecimal.valueOf(5.0);

    @Builder.Default
    @Column(name = "include_travel_cost", nullable = false)
    private Boolean includeTravelCost = false;

    @Builder.Default
    @Column(name = "travel_cost_per_km", precision = 6, scale = 2, nullable = false)
    private BigDecimal travelCostPerKm = BigDecimal.valueOf(10.0);

    @Builder.Default
    @Column(name = "sort_preference", nullable = false, length = 50)
    private String sortPreference = "BEST_VALUE"; // CHEAPEST, NEAREST, BEST_VALUE, ONE_STORE, MAX_SAVING
}
