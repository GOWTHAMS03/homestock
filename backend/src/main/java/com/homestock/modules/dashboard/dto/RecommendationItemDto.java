package com.homestock.modules.dashboard.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecommendationItemDto {
    private UUID itemId;
    private String name;
    private String categoryName;
    private BigDecimal currentQuantity;
    private BigDecimal recommendedQuantity;
    private String unit;
    private String rationale; // e.g. "Out of stock", "Running below minimum threshold"
}
