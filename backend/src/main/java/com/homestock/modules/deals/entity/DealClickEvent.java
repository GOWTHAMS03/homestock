package com.homestock.modules.deals.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.product.entity.Product;
import com.homestock.modules.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

/**
 * Deal click & affiliate attribution tracking entity.
 */
@Entity
@Table(name = "deal_click_events", indexes = {
        @Index(name = "idx_dce_user", columnList = "user_id"),
        @Index(name = "idx_dce_provider", columnList = "provider"),
        @Index(name = "idx_dce_clicked_at", columnList = "clicked_at")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DealClickEvent extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "deal_id")
    private UUID dealId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_id")
    private NearbyShop shop;

    @Column(name = "provider", nullable = false, length = 50)
    private String provider;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id")
    private Product product;

    @Column(name = "external_url", length = 1000)
    private String externalUrl;

    @Builder.Default
    @Column(name = "clicked_at", nullable = false)
    private Instant clickedAt = Instant.now();
}
