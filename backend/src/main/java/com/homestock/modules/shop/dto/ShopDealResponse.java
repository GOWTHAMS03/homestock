package com.homestock.modules.shop.dto;

import com.homestock.modules.shop.entity.ShopDeal;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopDealResponse {
    private UUID id;
    private UUID shopId;
    private UUID shopProductId;
    private String title;
    private String description;
    private String dealType;
    private BigDecimal originalPrice;
    private BigDecimal offerPrice;
    private BigDecimal discountPercent;
    private Instant startDate;
    private Instant endDate;
    private Boolean isActive;
    private Boolean isCurrentlyActive;

    // Customer discovery fields
    private String shopName;
    private String productName;

    public static ShopDealResponse fromEntity(ShopDeal deal) {
        return ShopDealResponse.builder()
                .id(deal.getId())
                .shopId(deal.getShop() != null ? deal.getShop().getId() : null)
                .shopProductId(deal.getShopProduct() != null ? deal.getShopProduct().getId() : null)
                .title(deal.getTitle())
                .description(deal.getDescription())
                .dealType(deal.getDealType())
                .originalPrice(deal.getOriginalPrice())
                .offerPrice(deal.getOfferPrice())
                .discountPercent(deal.getDiscountPercent())
                .startDate(deal.getStartDate())
                .endDate(deal.getEndDate())
                .isActive(deal.getIsActive())
                .isCurrentlyActive(deal.isCurrentlyActive())
                .shopName(deal.getShop() != null ? deal.getShop().getName() : null)
                .productName(deal.getShopProduct() != null ? deal.getShopProduct().getRawProductName() : null)
                .build();
    }
}
