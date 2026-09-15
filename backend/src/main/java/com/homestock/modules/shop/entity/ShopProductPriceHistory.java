package com.homestock.modules.shop.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.deals.entity.ShopProductOffer;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Audit trail for shop product price changes.
 */
@Entity
@Table(name = "shop_product_price_history", indexes = {
        @Index(name = "idx_spph_shop_product", columnList = "shop_product_id"),
        @Index(name = "idx_spph_created_at", columnList = "created_at")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopProductPriceHistory extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_product_id", nullable = false)
    private ShopProductOffer shopProduct;

    @Column(name = "old_price", precision = 12, scale = 2, nullable = false)
    private BigDecimal oldPrice;

    @Column(name = "new_price", precision = 12, scale = 2, nullable = false)
    private BigDecimal newPrice;

    @Column(name = "old_offer_price", precision = 12, scale = 2)
    private BigDecimal oldOfferPrice;

    @Column(name = "new_offer_price", precision = 12, scale = 2)
    private BigDecimal newOfferPrice;

    @Column(name = "changed_by")
    private UUID changedBy;

    @Column(name = "reason", length = 255)
    private String reason;
}
