package com.homestock.modules.shop.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Anonymous product search event for aggregated demand analytics.
 * No user identity is stored.
 */
@Entity
@Table(name = "shop_search_events", indexes = {
        @Index(name = "idx_sse_normalized", columnList = "normalized_query"),
        @Index(name = "idx_sse_searched_at", columnList = "searched_at"),
        @Index(name = "idx_sse_coords", columnList = "latitude, longitude")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopSearchEvent {

    @Id
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "search_query", nullable = false, length = 200)
    private String searchQuery;

    @Column(name = "normalized_query", nullable = false, length = 200)
    private String normalizedQuery;

    @Column(name = "latitude", precision = 10, scale = 7)
    private BigDecimal latitude;

    @Column(name = "longitude", precision = 10, scale = 7)
    private BigDecimal longitude;

    @Builder.Default
    @Column(name = "result_count", nullable = false)
    private Integer resultCount = 0;

    @Builder.Default
    @Column(name = "searched_at", nullable = false)
    private Instant searchedAt = Instant.now();

    @PrePersist
    protected void onPrePersist() {
        if (this.id == null) {
            this.id = UUID.randomUUID();
        }
    }
}
