package com.homestock.modules.away.repository;

import com.homestock.modules.away.entity.AwayPeriodSummary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AwayPeriodSummaryRepository extends JpaRepository<AwayPeriodSummary, UUID> {

    @Query("SELECT s FROM AwayPeriodSummary s WHERE s.home.id = :homeId AND s.user.id = :userId AND s.isReviewed = false ORDER BY s.createdAt DESC")
    List<AwayPeriodSummary> findUnreviewedSummaries(
            @Param("homeId") UUID homeId,
            @Param("userId") UUID userId
    );

    @Query("SELECT s FROM AwayPeriodSummary s WHERE s.home.id = :homeId AND s.user.id = :userId ORDER BY s.createdAt DESC")
    List<AwayPeriodSummary> findAllByHomeIdAndUserIdOrderByCreatedAtDesc(
            @Param("homeId") UUID homeId,
            @Param("userId") UUID userId
    );

    @Query("SELECT s FROM AwayPeriodSummary s WHERE s.home.id = :homeId AND s.user.id = :userId AND s.createdAt >= :since ORDER BY s.createdAt DESC")
    Optional<AwayPeriodSummary> findRecentSummary(
            @Param("homeId") UUID homeId,
            @Param("userId") UUID userId,
            @Param("since") Instant since
    );
}
