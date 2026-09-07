package com.homestock.modules.smartshopping.repository;

import com.homestock.modules.smartshopping.entity.PriceHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public interface PriceHistoryRepository extends JpaRepository<PriceHistory, UUID> {

    /**
     * Get recent price history for a specific product.
     */
    List<PriceHistory> findByProviderAndProviderProductIdAndRecordedAtAfterOrderByRecordedAtDesc(
            String provider, String providerProductId, Instant since);

    /**
     * Get the average effective price for a product over a time period.
     */
    @Query("SELECT AVG(ph.effectivePrice) FROM PriceHistory ph WHERE ph.provider = :provider AND ph.providerProductId = :productId AND ph.recordedAt >= :since")
    BigDecimal getAveragePrice(String provider, String productId, Instant since);

    /**
     * Cleanup old price history records.
     */
    void deleteByRecordedAtBefore(Instant cutoff);
}
