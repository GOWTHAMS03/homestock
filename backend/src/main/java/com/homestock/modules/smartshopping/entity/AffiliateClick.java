package com.homestock.modules.smartshopping.entity;

import com.homestock.core.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

/**
 * Records each affiliate link click for analytics and performance tracking.
 * Does not store personal or payment information.
 */
@Entity
@Table(name = "affiliate_clicks", indexes = {
        @Index(name = "idx_ac_home_provider", columnList = "home_id, provider"),
        @Index(name = "idx_ac_clicked_at", columnList = "clicked_at")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AffiliateClick extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "home_id", nullable = false)
    private UUID homeId;

    @Column(name = "shopping_item_id")
    private UUID shoppingItemId;

    @Column(name = "provider", nullable = false, length = 50)
    private String provider;

    @Column(name = "provider_product_id", length = 200)
    private String providerProductId;

    @Column(name = "clicked_at", nullable = false)
    private Instant clickedAt;

    @Column(name = "session_id")
    private UUID sessionId;

    @Column(name = "source_screen", length = 50)
    private String sourceScreen;
}
