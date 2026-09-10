package com.homestock.modules.sync.repository;

import com.homestock.modules.sync.entity.HomeChangeLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface HomeChangeLogRepository extends JpaRepository<HomeChangeLog, UUID> {

    @Query("SELECT COALESCE(MAX(c.changeVersion), 0) FROM HomeChangeLog c WHERE c.home.id = :homeId")
    Long findMaxVersionByHomeId(@Param("homeId") UUID homeId);

    List<HomeChangeLog> findByHomeIdAndChangeVersionGreaterThanOrderByChangeVersionAsc(
            UUID homeId, Long changeVersion);

    @Query("SELECT c FROM HomeChangeLog c WHERE c.home.id = :homeId AND c.changeVersion > :changeVersion ORDER BY c.changeVersion ASC")
    List<HomeChangeLog> findByHomeIdAndChangeVersionGreaterThan(
            @Param("homeId") UUID homeId,
            @Param("changeVersion") Long changeVersion,
            org.springframework.data.domain.Pageable pageable);
}

