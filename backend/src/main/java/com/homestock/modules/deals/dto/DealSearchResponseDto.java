package com.homestock.modules.deals.dto;

import com.homestock.modules.deals.model.NormalizedProductQuery;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Clean API response for Deal searches (Phase 19).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DealSearchResponseDto {
    private String query;
    private NormalizedProductQuery normalizedQuery;
    @Builder.Default
    private List<CanonicalDealDto> exactDeals = new ArrayList<>();
    @Builder.Default
    private List<CanonicalDealDto> alternativeDeals = new ArrayList<>();
    private Instant searchedAt;
    private Instant expiresAt;
    private String message;
    private int totalFound;
}
