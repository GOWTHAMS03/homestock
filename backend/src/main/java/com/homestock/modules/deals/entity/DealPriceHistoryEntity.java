package com.homestock.modules.deals.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.deals.model.DealSource;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Audit history of detected price changes for a deal.
 */
@Entity
@Table(name = "deal_price_history", indexes = {
        @Index(name = "idx_dph_deal_id", columnList = "deal_id"),
        @Index(name = "idx_dph_detected_at", columnList = "detected_at")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DealPriceHistoryEntity extends BaseEntity {

    @Column(name = "deal_id", nullable = false)
    private UUID dealId;

    @Column(name = "old_price", precision = 12, scale = 2, nullable = false)
    private BigDecimal oldPrice;

    @Column(name = "new_price", precision = 12, scale = 2, nullable = false)
    private BigDecimal newPrice;

    @Enumerated(EnumType.STRING)
    @Column(name = "source", nullable = false, length = 50)
    private DealSource source;

    @Column(name = "detected_at", nullable = false)
    private Instant detectedAt;

    @Column(name = "reason", length = 200)
    private String reason;
}
