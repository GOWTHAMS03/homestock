package com.homestock.modules.voice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductMatchResult {

    public enum MatchType {
        EXACT,
        ALIAS,
        BARCODE,
        FUZZY,
        SEMANTIC,
        NONE
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ProductCandidate {
        private UUID productId;
        private String productName;
        private String brand;
        private String category;
        private double score;
        private String matchReason;
    }

    private UUID productId;
    private String productName;
    private String category;
    private String defaultUnit;
    @Builder.Default
    private double confidence = 0.0;
    @Builder.Default
    private MatchType matchType = MatchType.NONE;
    @Builder.Default
    private List<ProductCandidate> candidates = new ArrayList<>();
}

