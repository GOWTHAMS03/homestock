package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

/**
 * End-to-end debug audit trace explaining every decision in the search pipeline:
 * User Input -> Extracted Intent -> Queries -> Raw Engine Results -> Normalized ->
 * Rejected Candidates (with exact reasons) -> Valid Candidates -> Clusters -> Deals.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SearchDebugTrace {
    private String rawInput;
    private ProductIdentity resolvedIdentity;

    @Builder.Default
    private List<String> generatedQueries = new ArrayList<>();

    private int rawEngineCandidatesCount;

    @Builder.Default
    private List<RejectedCandidate> rejectedCandidates = new ArrayList<>();

    private int validCandidatesCount;
    private int productClustersCount;
    private int clustersCount;

    public int getClustersCount() {
        return clustersCount > 0 ? clustersCount : productClustersCount;
    }

    public void setClustersCount(int count) {
        this.clustersCount = count;
        this.productClustersCount = count;
    }

    public static class SearchDebugTraceBuilder {
        public SearchDebugTraceBuilder clustersCount(int count) {
            this.clustersCount = count;
            this.productClustersCount = count;
            return this;
        }
    }

    @Builder.Default
    private List<String> executionNotes = new ArrayList<>();
}
