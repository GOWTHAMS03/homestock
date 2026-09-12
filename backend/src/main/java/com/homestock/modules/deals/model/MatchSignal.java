package com.homestock.modules.deals.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * An individual scoring signal in the Product Matching Engine.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MatchSignal {
    private String name;
    private double weight;
    private double score; // 0.0 to 1.0
    private boolean passed;
    private String detail;

    public double getWeightedContribution() {
        return weight * score;
    }
}
