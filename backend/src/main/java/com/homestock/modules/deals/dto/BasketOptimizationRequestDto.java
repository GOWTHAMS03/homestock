package com.homestock.modules.deals.dto;

import lombok.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BasketOptimizationRequestDto {
    private UUID homeId;
    private UUID shoppingListId;
    private List<BasketItemQuery> items;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private Double radiusKm;
    private Boolean includeTravelCost;
    private String sortPreference; // CHEAPEST, NEAREST, BEST_VALUE, ONE_STORE, MAX_SAVING

    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BasketItemQuery {
        private UUID shoppingListItemId;
        private UUID productId;
        private String itemName;
        private BigDecimal quantity;
        private String unit;
    }
}
