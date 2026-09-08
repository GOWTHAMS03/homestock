package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BasketComparisonRequest {
    private List<UUID> itemIds;
    @Builder.Default
    private String rankingStrategy = "BEST_PRICE";
    private String preferredStore;
}
