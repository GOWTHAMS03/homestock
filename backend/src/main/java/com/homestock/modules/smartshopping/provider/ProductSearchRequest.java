package com.homestock.modules.smartshopping.provider;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;

/**
 * Normalized search request sent to every provider.
 * Providers translate this into their specific API format.
 */
@Data
@Builder
public class ProductSearchRequest {

    /** The item name to search for (e.g. "Aashirvaad Atta") */
    private String itemName;

    /** Brand filter, if available (e.g. "Aashirvaad") */
    private String brand;

    /** Desired quantity (e.g. 5) */
    private BigDecimal quantity;

    /** Desired unit (e.g. "kg") */
    private String unit;

    /** Product category hint (e.g. "Kitchen", "Cleaning") */
    private String category;

    /** Maximum number of results per provider */
    @Builder.Default
    private int maxResults = 5;
}
