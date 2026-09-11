package com.homestock.modules.notification.ml;

import com.homestock.modules.notification.dto.NotificationCandidate;
import com.homestock.modules.notification.entity.NotificationEvent;
import com.homestock.modules.notification.entity.NotificationPreference;
import com.homestock.modules.notification.entity.NotificationPriority;
import com.homestock.modules.notification.repository.NotificationEventRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.*;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * NotificationTimingService:
 * Learns peak user engagement hours from historical notification opens, clicks, and actions.
 * Delays non-urgent alerts to the user's preferred interaction window while dispatching
 * critical alerts immediately and strictly observing quiet hours.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationTimingService {

    private final NotificationEventRepository notificationEventRepository;

    // Default household engagement peak (18:30 / 6:30 PM)
    private static final LocalTime DEFAULT_PEAK_TIME = LocalTime.of(18, 30);

    /**
     * Determines the optimal delivery timestamp for a candidate notification.
     */
    public TimingRecommendation determineDeliveryTime(NotificationCandidate candidate, NotificationPreference preference) {
        Instant now = Instant.now();
        LocalTime currentTime = LocalTime.now();

        boolean isCritical = candidate.getBasePriority() == NotificationPriority.CRITICAL;
        boolean inQuietHours = preference != null && preference.isInsideQuietHours(currentTime);

        // 1. Critical notifications: send immediately unless quiet hours apply (critical can bypass or defer to end of quiet hours)
        if (isCritical) {
            if (inQuietHours) {
                // If critical, even in quiet hours send if life/safety, otherwise schedule right at quiet hours end
                LocalTime endQuiet = preference.getQuietHoursEnd() != null ? preference.getQuietHoursEnd() : LocalTime.of(7, 0);
                Instant nextActive = calculateNextInstant(endQuiet);
                return new TimingRecommendation(false, nextActive, "Deferred to quiet hours end");
            }
            return new TimingRecommendation(true, now, "Immediate delivery for critical priority");
        }

        // 2. If currently in quiet hours, must delay
        if (inQuietHours) {
            LocalTime endQuiet = preference.getQuietHoursEnd() != null ? preference.getQuietHoursEnd() : LocalTime.of(7, 0);
            Instant nextActive = calculateNextInstant(endQuiet);
            return new TimingRecommendation(false, nextActive, "Currently inside quiet hours");
        }

        // 3. Learn user's optimal interaction hour
        UUID userId = candidate.getRecipientUser() != null ? candidate.getRecipientUser().getId() : null;
        LocalTime optimalTime = getLearnedBestTime(userId);

        // If current time is within 45 minutes of optimal time, send now
        long minutesDifference = Math.abs(Duration.between(currentTime, optimalTime).toMinutes());
        if (minutesDifference <= 45) {
            return new TimingRecommendation(true, now, "Currently within optimal engagement window (~" + optimalTime + ")");
        }

        // 4. Otherwise, if not urgent, schedule for user's next optimal window
        Instant nextOptimalInstant = calculateNextInstant(optimalTime);
        return new TimingRecommendation(false, nextOptimalInstant, "Scheduled for user's peak interaction window at " + optimalTime);
    }

    /**
     * Learns peak interaction hour from user's historical events.
     */
    public LocalTime getLearnedBestTime(UUID userId) {
        if (userId == null) return DEFAULT_PEAK_TIME;

        List<NotificationEvent> interactions = notificationEventRepository.findPositiveInteractionsByUserId(userId);
        if (interactions.size() < 3) {
            return DEFAULT_PEAK_TIME;
        }

        Map<Integer, Integer> hourCounts = new HashMap<>();
        for (NotificationEvent event : interactions) {
            ZonedDateTime zdt = event.getOccurredAt().atZone(ZoneId.systemDefault());
            int hour = zdt.getHour();
            hourCounts.put(hour, hourCounts.getOrDefault(hour, 0) + 1);
        }

        int bestHour = 18;
        int maxCount = -1;
        for (Map.Entry<Integer, Integer> entry : hourCounts.entrySet()) {
            if (entry.getValue() > maxCount) {
                maxCount = entry.getValue();
                bestHour = entry.getKey();
            }
        }

        return LocalTime.of(bestHour, 30);
    }

    private Instant calculateNextInstant(LocalTime targetTime) {
        LocalDate today = LocalDate.now();
        LocalTime now = LocalTime.now();

        LocalDate targetDate = now.isAfter(targetTime) ? today.plusDays(1) : today;
        return targetDate.atTime(targetTime).atZone(ZoneId.systemDefault()).toInstant();
    }

    public record TimingRecommendation(
            boolean sendImmediately,
            Instant deliveryTimestamp,
            String reason
    ) {}
}
