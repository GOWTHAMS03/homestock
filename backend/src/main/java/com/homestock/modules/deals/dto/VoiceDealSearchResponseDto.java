package com.homestock.modules.deals.dto;

import lombok.*;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VoiceDealSearchResponseDto {
    private String transcript;
    private String detectedLanguage;
    private String intent; // SEARCH_DEAL, FIND_BEST_BASKET, NEARBY_SHOP_PRICE
    private String parsedProduct;
    private BigDecimal parsedQuantity;
    private String parsedUnit;
    private String conversationalReply; // Tamil / Tanglish / English response
    private ShopDealDto bestNearbyDeal;
    private List<ShopDealDto> otherDeals;
    private BasketOptimizationResponseDto basketOptimization;
}
