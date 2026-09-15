package com.homestock.modules.shop.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.deals.entity.NearbyShop;
import com.homestock.modules.deals.entity.ShopProductOffer;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Shop Owner-created deals and offers.
 */
@Entity
@Table(name = "shop_deals", indexes = {
        @Index(name = "idx_sd_shop", columnList = "shop_id"),
        @Index(name = "idx_sd_active", columnList = "is_active, end_date"),
        @Index(name = "idx_sd_dates", columnList = "start_date, end_date")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopDeal extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_id", nullable = false)
    private NearbyShop shop;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_product_id")
    private ShopProductOffer shopProduct;

    @Column(name = "title", nullable = false, length = 200)
    private String title;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Builder.Default
    @Column(name = "deal_type", nullable = false, length = 30)
    private String dealType = "DISCOUNT"; // DISCOUNT, SPECIAL_PRICE, BUY_X_GET_Y, LIMITED_TIME

    @Column(name = "original_price", precision = 12, scale = 2)
    private BigDecimal originalPrice;

    @Column(name = "offer_price", precision = 12, scale = 2)
    private BigDecimal offerPrice;

    @Column(name = "discount_percent", precision = 5, scale = 2)
    private BigDecimal discountPercent;

    @Column(name = "start_date", nullable = false)
    private Instant startDate;

    @Column(name = "end_date", nullable = false)
    private Instant endDate;

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    public boolean isCurrentlyActive() {
        if (!Boolean.TRUE.equals(isActive)) return false;
        Instant now = Instant.now();
        return !now.isBefore(startDate) && !now.isAfter(endDate);
    }
}
