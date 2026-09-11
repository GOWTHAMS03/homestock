package com.homestock.modules.away.service;

import com.homestock.modules.away.entity.AwayPeriodSummary;
import com.homestock.modules.away.entity.AwayPrediction;
import com.homestock.modules.away.entity.AwayPredictionType;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.notification.entity.NotificationType;
import com.homestock.modules.notification.service.NotificationEngine;
import com.homestock.modules.user.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AwayNotificationService {

    private final NotificationEngine notificationEngine;

    public void notifyUserIfSignificant(AwayPeriodSummary summary, List<AwayPrediction> topPredictions) {
        if (summary == null || summary.getImportantChanges() <= 0 || topPredictions == null || topPredictions.isEmpty()) {
            return;
        }

        // Only notify if there are urgent items (ran out, low stock, or expiry risk)
        List<AwayPrediction> urgentItems = topPredictions.stream()
                .filter(p -> p.getPredictionType() == AwayPredictionType.LIKELY_RAN_OUT ||
                        p.getPredictionType() == AwayPredictionType.MAY_HAVE_EXPIRED ||
                        p.getPredictionType() == AwayPredictionType.LIKELY_LOW)
                .toList();

        if (urgentItems.isEmpty()) {
            log.debug("[AwayNotificationService] No high urgency predictions for summary {}. Suppressing push.", summary.getId());
            return;
        }

        Home home = summary.getHome();
        User user = summary.getUser();
        if (home == null || user == null) return;

        String itemNames = urgentItems.stream()
                .limit(2)
                .map(AwayPrediction::getItemName)
                .collect(Collectors.joining(" and "));

        String title = String.format("While you were away for %d days 👋", summary.getAwayDays());
        String body = String.format("%s may need attention. Tap to review.", itemNames);

        String dedupKey = "AWAY_SUMMARY:" + home.getId() + ":" + user.getId() + ":" + summary.getId();

        Map<String, String> dataPayload = Map.of(
                "action", "VIEW_AWAY_SUMMARY",
                "summaryId", summary.getId().toString(),
                "homeId", home.getId().toString(),
                "type", NotificationType.SMART_RESTOCK_SUGGESTION.name()
        );

        notificationEngine.dispatchUserNotification(
                home,
                user,
                NotificationType.SMART_RESTOCK_SUGGESTION,
                title,
                body,
                dedupKey,
                dataPayload
        );

        log.info("[AwayNotificationService] Dispatched smart away notification to user {} for summary {}",
                user.getId(), summary.getId());
    }
}
