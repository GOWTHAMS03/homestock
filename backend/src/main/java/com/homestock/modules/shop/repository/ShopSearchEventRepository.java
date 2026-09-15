package com.homestock.modules.shop.repository;

import com.homestock.modules.shop.entity.ShopSearchEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public interface ShopSearchEventRepository extends JpaRepository<ShopSearchEvent, UUID> {

    /**
     * Get top searched product queries near a location within a time window.
     * Returns [normalizedQuery, count] pairs ordered by frequency.
     */
    @Query("SELECT e.normalizedQuery, COUNT(e) as cnt FROM ShopSearchEvent e " +
           "WHERE e.searchedAt >= :since " +
           "AND e.latitude BETWEEN :minLat AND :maxLat " +
           "AND e.longitude BETWEEN :minLon AND :maxLon " +
           "GROUP BY e.normalizedQuery ORDER BY cnt DESC")
    List<Object[]> findTopSearchesNearLocation(
            @Param("since") Instant since,
            @Param("minLat") BigDecimal minLat,
            @Param("maxLat") BigDecimal maxLat,
            @Param("minLon") BigDecimal minLon,
            @Param("maxLon") BigDecimal maxLon
    );
}
