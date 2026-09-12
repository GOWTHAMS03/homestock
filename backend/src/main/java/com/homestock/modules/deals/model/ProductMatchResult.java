package com.homestock.modules.deals.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

/**
 * Encapsulates the evaluation produced by the Product Matching Engine.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductMatchResult {
    private boolean exactMatch;
    private double matchScore; // 0.0 to 1.0 (or percentage)
    private String reason;
    private DealMatchCategory category;
    @Builder.Default
    private List<MatchSignal> signals = new ArrayList<>();

    public boolean isAcceptable() {
        return category == DealMatchCategory.EXACT_MATCH || category == DealMatchCategory.SIMILAR_ALTERNATIVE;
    }

    public static ProductMatchResult rejected(String reason, List<MatchSignal> signals) {
        return ProductMatchResult.builder()
                .exactMatch(false)
                .matchScore(0.0)
                .reason(reason)
                .category(DealMatchCategory.REJECTED)
                .signals(signals != null ? signals : new ArrayList<>())
                .build();
    }
}
