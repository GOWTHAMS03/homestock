package com.homestock.modules.notification.repository;

import com.homestock.modules.notification.entity.NotificationEvent;
import com.homestock.modules.notification.entity.NotificationEventType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface NotificationEventRepository extends JpaRepository<NotificationEvent, UUID> {

    List<NotificationEvent> findByUserIdOrderByOccurredAtDesc(UUID userId);

    List<NotificationEvent> findByHomeIdOrderByOccurredAtDesc(UUID homeId);

    Optional<NotificationEvent> findTopByDedupKeyOrderByOccurredAtDesc(String dedupKey);

    Optional<NotificationEvent> findTopByNotificationIdOrderByOccurredAtDesc(UUID notificationId);

    @Query("SELECT COUNT(e) FROM NotificationEvent e WHERE e.user.id = :userId AND e.eventType = :eventType AND e.occurredAt >= :since")
    long countByUserIdAndEventTypeSince(
            @Param("userId") UUID userId,
            @Param("eventType") NotificationEventType eventType,
            @Param("since") Instant since
    );

    @Query("SELECT COUNT(e) FROM NotificationEvent e WHERE e.user.id = :userId AND e.occurredAt >= :since")
    long countTotalByUserIdSince(@Param("userId") UUID userId, @Param("since") Instant since);

    @Query("SELECT COUNT(e) FROM NotificationEvent e WHERE e.user.id = :userId AND e.channel = 'PUSH' AND e.eventType = 'SENT' AND e.occurredAt >= :since")
    long countPushSentByUserIdSince(@Param("userId") UUID userId, @Param("since") Instant since);

    @Query("SELECT e FROM NotificationEvent e WHERE e.user.id = :userId AND e.eventType IN ('OPENED', 'CLICKED', 'ACTION_TAKEN') ORDER BY e.occurredAt DESC")
    List<NotificationEvent> findPositiveInteractionsByUserId(@Param("userId") UUID userId);

    @Query("SELECT COUNT(e) FROM NotificationEvent e WHERE e.home.id = :homeId AND e.inventoryItem.id = :itemId AND e.eventType = 'ACTION_TAKEN' AND e.occurredAt >= :since")
    long countActionsForItemSince(
            @Param("homeId") UUID homeId,
            @Param("itemId") UUID itemId,
            @Param("since") Instant since
    );

    @Query("SELECT COUNT(e) FROM NotificationEvent e WHERE e.home.id = :homeId AND e.occurredAt >= :since")
    long countHomeEventsSince(@Param("homeId") UUID homeId, @Param("since") Instant since);

    @Query("SELECT COUNT(e) FROM NotificationEvent e WHERE e.home.id = :homeId AND e.eventType = :eventType AND e.occurredAt >= :since")
    long countHomeEventsByEventTypeSince(
            @Param("homeId") UUID homeId,
            @Param("eventType") NotificationEventType eventType,
            @Param("since") Instant since
    );
}
