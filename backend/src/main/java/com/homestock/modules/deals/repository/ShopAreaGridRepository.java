package com.homestock.modules.deals.repository;

import com.homestock.modules.deals.entity.ShopAreaGrid;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
public interface ShopAreaGridRepository extends JpaRepository<ShopAreaGrid, String> {

    Optional<ShopAreaGrid> findByGridKey(String gridKey);

    @Query("SELECT g FROM ShopAreaGrid g WHERE g.syncStatus = 'PENDING' OR " +
           "(g.lastSyncAt IS NOT NULL AND g.lastSyncAt < :staleThreshold AND g.syncStatus != 'SYNCING') " +
           "ORDER BY g.updatedAt ASC")
    List<ShopAreaGrid> findStaleOrPendingGrids(@Param("staleThreshold") Instant staleThreshold, Pageable pageable);

    @Modifying
    @Query("UPDATE ShopAreaGrid g SET g.syncStatus = 'SYNCING', g.updatedAt = :now, g.syncAttempts = g.syncAttempts + 1 " +
           "WHERE g.gridKey = :gridKey AND (g.syncStatus != 'SYNCING' OR g.updatedAt < :lockExpiry)")
    int claimSyncTask(@Param("gridKey") String gridKey, @Param("now") Instant now, @Param("lockExpiry") Instant lockExpiry);
}
