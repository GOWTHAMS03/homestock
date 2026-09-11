package com.homestock.modules.away.repository;

import com.homestock.modules.away.entity.UserActivityLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserActivityLogRepository extends JpaRepository<UserActivityLog, UUID> {

    @Query("SELECT MAX(a.occurredAt) FROM UserActivityLog a WHERE a.user.id = :userId")
    Optional<Instant> findLatestActivityByUserId(@Param("userId") UUID userId);

    @Query("SELECT MAX(a.occurredAt) FROM UserActivityLog a WHERE a.home.id = :homeId AND a.user.id != :excludedUserId")
    Optional<Instant> findLatestFamilyActivityExcludingUser(
            @Param("homeId") UUID homeId,
            @Param("excludedUserId") UUID excludedUserId
    );

    @Query("SELECT COUNT(DISTINCT DATE(a.occurredAt)) FROM UserActivityLog a WHERE a.user.id = :userId AND a.occurredAt >= :since")
    long countDistinctActiveDaysSince(@Param("userId") UUID userId, @Param("since") Instant since);
}
