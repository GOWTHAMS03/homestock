package com.homestock.modules.smartshopping.service;

import com.homestock.modules.smartshopping.dto.ProductOfferDto;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service to rank product offers based on explicit user strategies:
 * BEST_PRICE, BEST_VALUE, FASTEST, PREFERRED_STORE, EXACT_MATCH.
 * Also evaluates price freshness (FRESH, RECENT, STALE).
 */
@Service
public class OfferRankingService {

    public enum RankingStrategy {
        BEST_PRICE,
        BEST_VALUE,
        FASTEST,
        PREFERRED_STORE,
        EXACT_MATCH
    }

    public enum FreshnessStatus {
        FRESH,    // < 15 minutes
        RECENT,   // 15 - 60 minutes
        STALE     // > 60 minutes
    }

    /**
     * Determines freshness tier for an offer based on when it was checked.
     */
    public FreshnessStatus evaluateFreshness(Instant lastCheckedAt) {
        if (lastCheckedAt == null) {
            return FreshnessStatus.STALE;
        }
        long minutes = Duration.between(lastCheckedAt, Instant.now()).toMinutes();
        if (minutes < 15) {
            return FreshnessStatus.FRESH;
        } else if (minutes <= 60) {
            return FreshnessStatus.RECENT;
        } else {
            return FreshnessStatus.STALE;
        }
    }

    /**
     * Rank a list of offers according to the desired strategy.
     */
    public List<ProductOfferDto> rankOffers(List<ProductOfferDto> offers, RankingStrategy strategy, String preferredStore) {
        if (offers == null || offers.isEmpty()) {
            return List.of();
        }

        Comparator<ProductOfferDto> comparator;

        switch (strategy) {
            case BEST_VALUE:
                // Compare price per unit if available, fallback to effective price
                comparator = Comparator.comparing(
                        o -> o.getPricePerUnit() != null ? o.getPricePerUnit() : o.getEffectivePrice(),
                        Comparator.nullsLast(BigDecimal::compareTo)
                );
                break;

            case FASTEST:
                // Fast delivery prioritized
                comparator = Comparator.comparing((ProductOfferDto o) -> {
                    String del = o.getEstimatedDelivery() != null ? o.getEstimatedDelivery().toLowerCase() : "";
                    if (del.contains("10 min") || del.contains("quick") || del.contains("instant")) return 1;
                    if (del.contains("today") || del.contains("same day")) return 2;
                    if (del.contains("tomorrow") || del.contains("next day")) return 3;
                    return 4;
                }).thenComparing(ProductOfferDto::getEffectivePrice, Comparator.nullsLast(BigDecimal::compareTo));
                break;

            case PREFERRED_STORE:
                comparator = Comparator.comparing((ProductOfferDto o) -> {
                    if (preferredStore != null && o.getProvider() != null &&
                            o.getProvider().equalsIgnoreCase(preferredStore.trim())) {
                        return 0;
                    }
                    return 1;
                }).thenComparing(ProductOfferDto::getEffectivePrice, Comparator.nullsLast(BigDecimal::compareTo));
                break;

            case EXACT_MATCH:
                comparator = Comparator.comparing((ProductOfferDto o) -> {
                    if ("EXACT".equalsIgnoreCase(o.getMatchType())) return 0;
                    if ("SIMILAR".equalsIgnoreCase(o.getMatchType())) return 1;
                    return 2;
                }).thenComparing(ProductOfferDto::getEffectivePrice, Comparator.nullsLast(BigDecimal::compareTo));
                break;

            case BEST_PRICE:
            default:
                comparator = Comparator.comparing(
                        ProductOfferDto::getEffectivePrice,
                        Comparator.nullsLast(BigDecimal::compareTo)
                );
                break;
        }

        return offers.stream()
                .sorted(comparator)
                .collect(Collectors.toList());
    }
}
