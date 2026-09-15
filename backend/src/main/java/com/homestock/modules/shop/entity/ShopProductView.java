package com.homestock.modules.shop.entity;

import com.homestock.modules.deals.entity.NearbyShop;
import com.homestock.modules.deals.entity.ShopProductOffer;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

/**
 * Anonymous shop/product view tracking for analytics dashboard.
 */
@Entity
@Table(name = "shop_product_views", indexes = {
        @Index(name = "idx_spv_shop", columnList = "shop_id"),
        @Index(name = "idx_spv_viewed_at", columnList = "viewed_at"),
        @Index(name = "idx_spv_product", columnList = "shop_product_id")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopProductView {

    @Id
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_id", nullable = false)
    private NearbyShop shop;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_product_id")
    private ShopProductOffer shopProduct;

    @Builder.Default
    @Column(name = "viewed_at", nullable = false)
    private Instant viewedAt = Instant.now();

    @PrePersist
    protected void onPrePersist() {
        if (this.id == null) {
            this.id = UUID.randomUUID();
        }
    }
}
