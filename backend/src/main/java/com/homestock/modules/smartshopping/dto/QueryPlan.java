package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

/**
 * Identity-aware query generation plan implementing progressive query relaxation (Levels 1 to 5).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class QueryPlan {

    /** Level 1: Exact user formulation */
    private String level1ExactQuery;

    /** Level 2: Normalized exact query with canonical units */
    private String level2NormalizedExactQuery;

    /** Level 3: Canonical brand + product name + normalized pack size */
    private String level3BrandProductSizeQuery;

    /** Level 4: Canonical brand + product name */
    private String level4BrandProductQuery;

    /** Level 5: Broader product query (only executed when fallback is allowed) */
    private String level5BroaderQuery;

    /** Ordered list of active query requests */
    @Builder.Default
    private List<String> activeQueries = new ArrayList<>();
}
