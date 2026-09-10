package com.homestock.modules.notification.repository;

import com.homestock.modules.notification.entity.NotificationDeduplication;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface NotificationDeduplicationRepository extends JpaRepository<NotificationDeduplication, UUID> {
    Optional<NotificationDeduplication> findByDedupKey(String dedupKey);

    @Modifying
    @Query("DELETE FROM NotificationDeduplication d WHERE d.lastSentAt < :cutoff")
    int deleteOlderThan(@Param("cutoff") Instant cutoff);
}

