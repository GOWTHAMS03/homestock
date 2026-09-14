package com.homestock.modules.deals.dto;

import lombok.*;

import java.util.List;

/**
 * Standard API response metadata envelope for nearby shop queries.
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NearbyShopsResponseDto {

    private List<NearbyShopDto> shops;

    /**
     * Source of the results: CACHE, DATABASE, USER_DATA, FALLBACK
     */
    private String source;

    /**
     * Freshness status: FRESH (synced < 12h), STALE (synced >= 12h), UNKNOWN (unverified/fallback)
     */
    private String dataFreshness;

    private Integer radiusMeters;

    private Boolean refreshInProgress;

    private String gridKey;
}
