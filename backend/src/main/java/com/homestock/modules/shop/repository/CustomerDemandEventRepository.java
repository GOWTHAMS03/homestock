package com.homestock.modules.shop.repository;

import com.homestock.modules.shop.entity.CustomerDemandEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public interface CustomerDemandEventRepository extends JpaRepository<CustomerDemandEvent, UUID> {

    @Query("SELECT e FROM CustomerDemandEvent e WHERE " +
           "e.createdAt >= :startDate AND e.createdAt <= :endDate AND " +
           "e.latitude BETWEEN :minLat AND :maxLat AND " +
           "e.longitude BETWEEN :minLon AND :maxLon")
    List<CustomerDemandEvent> findEventsInBoundingBoxAndDateRange(
            @Param("minLat") BigDecimal minLat,
            @Param("maxLat") BigDecimal maxLat,
            @Param("minLon") BigDecimal minLon,
            @Param("maxLon") BigDecimal maxLon,
            @Param("startDate") Instant startDate,
            @Param("endDate") Instant endDate
    );

    @Query("SELECT e FROM CustomerDemandEvent e WHERE " +
           "(LOWER(e.normalizedQuery) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           " LOWER(e.queryText) LIKE LOWER(CONCAT('%', :query, '%'))) AND " +
           "e.createdAt >= :startDate AND e.createdAt <= :endDate AND " +
           "e.latitude BETWEEN :minLat AND :maxLat AND " +
           "e.longitude BETWEEN :minLon AND :maxLon")
    List<CustomerDemandEvent> findEventsByQueryInBoundingBox(
            @Param("query") String query,
            @Param("minLat") BigDecimal minLat,
            @Param("maxLat") BigDecimal maxLat,
            @Param("minLon") BigDecimal minLon,
            @Param("maxLon") BigDecimal maxLon,
            @Param("startDate") Instant startDate,
            @Param("endDate") Instant endDate
    );

    @Modifying
    @Query("DELETE FROM CustomerDemandEvent e WHERE e.createdAt < :cutoff")
    int purgeOldEvents(@Param("cutoff") Instant cutoff);
}
