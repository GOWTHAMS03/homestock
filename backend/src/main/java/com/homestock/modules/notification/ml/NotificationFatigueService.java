package com.homestock.modules.notification.ml;

import com.homestock.modules.notification.entity.NotificationEventType;
import com.homestock.modules.notification.repository.NotificationEventRepository;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

/**
 * NotificationFatigueService:
 * Monitors notification velocity, daily ceilings, hourly bursts, and recent dismissals
 * to calculate a normalized fatigueScore (0.0 to 1.0) and prevent user notification overload.
 */
@Slf4j
@Service
@Getter
@Setter
@RequiredArgsConstructor
public class NotificationFatigueService {

    private final NotificationEventRepository notificationEventRepository;

    @Value("${app.notifications.limits.max-push-per-day:5}")
    private int maxPushPerDay = 5;

    @Value("${app.notifications.limits.max-notifications-per-hour:2}")
    private int maxNotificationsPerHour = 2;

    @Value("${app.notifications.limits.consecutive-dismissals-threshold:3}")
    private int consecutiveDismissalsThreshold = 3;

    public FatigueAssessment calculateFatigue(UUID userId) {
        if (userId == null) {
            return new FatigueAssessment(0.0, false, false, "No user ID");
        }

        Instant oneHourAgo = Instant.now().minus(Duration.ofHours(1));
        Instant oneDayAgo = Instant.now().minus(Duration.ofHours(24));

        long count1h = notificationEventRepository.countTotalByUserIdSince(userId, oneHourAgo);
        long pushCount24h = notificationEventRepository.countPushSentByUserIdSince(userId, oneDayAgo);
        long dismissed24h = notificationEventRepository.countByUserIdAndEventTypeSince(userId, NotificationEventType.DISMISSED, oneDayAgo);
        long opened24h = notificationEventRepository.countByUserIdAndEventTypeSince(userId, NotificationEventType.OPENED, oneDayAgo);

        boolean hourlyExceeded = count1h >= maxNotificationsPerHour;
        boolean dailyPushExceeded = pushCount24h >= maxPushPerDay;

        // Component 1: Hourly saturation (0.0 to 1.0)
        double hourlySaturation = (double) count1h / Math.max(1, maxNotificationsPerHour);

        // Component 2: Daily push saturation (0.0 to 1.0)
        double dailySaturation = (double) pushCount24h / Math.max(1, maxPushPerDay);

        // Component 3: Negative engagement ratio (dismissals vs opens)
        double dismissRatio = 0.0;
        long totalInteractions = dismissed24h + opened24h;
        if (totalInteractions > 0) {
            dismissRatio = (double) dismissed24h / totalInteractions;
        }

        double rawScore = (hourlySaturation * 0.45) + (dailySaturation * 0.35) + (dismissRatio * 0.20);
        double fatigueScore = Math.max(0.0, Math.min(1.0, rawScore));

        String reason = String.format(
                "HourlySent: %d/%d, DailyPush: %d/%d, DismissRatio: %.2f",
                count1h, maxNotificationsPerHour, pushCount24h, maxPushPerDay, dismissRatio
        );

        return new FatigueAssessment(fatigueScore, dailyPushExceeded, hourlyExceeded, reason);
    }

    public record FatigueAssessment(
            double fatigueScore,
            boolean isDailyPushExceeded,
            boolean isHourlyExceeded,
            String diagnosticReason
    ) {}
}
