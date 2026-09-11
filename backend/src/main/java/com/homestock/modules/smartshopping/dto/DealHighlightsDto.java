package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DealHighlightsDto {
    private ProductDealDto lowestPrice;
    private ProductDealDto bestValue;
    private ProductDealDto popular;
}
