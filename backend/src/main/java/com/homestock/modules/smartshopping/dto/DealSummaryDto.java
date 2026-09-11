package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DealSummaryDto {
    private int totalProducts;
    private BigDecimal priceRangeMin;
    private BigDecimal priceRangeMax;
    private BigDecimal lowestPrice;
    private BigDecimal bestUnitValue;
    private String bestUnitValueLabel;
    private String aiRecommendation;
}
