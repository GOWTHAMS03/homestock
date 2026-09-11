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
    /** Structured shopping item input summary */
    private ShoppingItemIntentDto shoppingItem;

    /** Classified search intent category */
    private SearchIntent searchIntent;

    /** Overall match status for the search */
    private MatchStatus matchStatus;

    /** Primary deals list (matching intent) */
    private List<ProductDealDto> deals;

    /** Alias for deals to guarantee backward compatibility with existing clients */
    private List<ProductDealDto> products;

    /** Strictly verified exact deals (brand + product + pack size match) */
    private List<ProductDealDto> exactDeals;

    /** Separated alternative or similar products (shown only when exact is missing or as separate recommendations) */
    private List<ProductDealDto> similarDeals;

    /** Structured rich product intent */
    private ProductIntent productIntent;

    /** Legacy search intent DTO retained for backward compatibility */
    private ProductSearchIntentDto intent;

    /** AI summary */
    private DealSummaryDto summary;

    /** Deals highlights (Lowest price, Best value, Popular) */
    private DealHighlightsDto highlights;

    /** Dynamic filter facets */
    private DealFiltersDto filters;

    /** Descriptive status or failure message */
    private String message;
}
