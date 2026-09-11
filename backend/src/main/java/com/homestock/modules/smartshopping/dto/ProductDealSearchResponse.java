package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductDealSearchResponse {
    private ProductSearchIntentDto intent;
    private DealSummaryDto summary;
    private DealHighlightsDto highlights;
    private List<ProductDealDto> products;
    private DealFiltersDto filters;
}
