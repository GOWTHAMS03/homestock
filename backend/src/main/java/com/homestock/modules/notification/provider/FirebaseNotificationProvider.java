package com.homestock.modules.notification.provider;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.BatchResponse;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.MulticastMessage;
import com.google.firebase.messaging.SendResponse;
import com.homestock.modules.notification.entity.DeviceToken;
import com.homestock.modules.notification.entity.NotificationPriority;
import com.homestock.modules.notification.entity.NotificationType;
import com.homestock.modules.notification.repository.DeviceTokenRepository;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.List;
import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class FirebaseNotificationProvider {

    private final DeviceTokenRepository deviceTokenRepository;

    @Value("${app.notifications.firebase.credentials-path:}")
    private String firebaseCredentialsPath;

    private boolean isFirebaseInitialized = false;

    @PostConstruct
    public void init() {
        try {
            if (FirebaseApp.getApps().isEmpty()) {
                InputStream serviceAccount = null;

                if (firebaseCredentialsPath != null && !firebaseCredentialsPath.isBlank()) {
                    File file = new File(firebaseCredentialsPath);
                    if (file.exists()) {
                        serviceAccount = new FileInputStream(file);
                        log.info("Loading Firebase credentials from: {}", firebaseCredentialsPath);
                    } else {
                        log.warn("Configured Firebase credentials file not found at: {}", firebaseCredentialsPath);
                    }
                }

                // Fallback to classpath if present
                if (serviceAccount == null) {
                    serviceAccount = getClass().getResourceAsStream("/firebase-service-account.json");
                }

                if (serviceAccount != null) {
                    FirebaseOptions options = FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                            .build();
                    FirebaseApp.initializeApp(options);
                    isFirebaseInitialized = true;
                    log.info("Firebase Admin SDK successfully initialized.");
                } else {
                    log.info("No Firebase credentials provided. FCM push notification provider will operate in local/mock mode.");
                }
            } else {
                isFirebaseInitialized = true;
            }
        } catch (Exception e) {
            log.warn("Failed to initialize Firebase Admin SDK (push notifications will operate in local/mock mode): {}", e.getMessage());
            isFirebaseInitialized = false;
        }
    }

    public boolean isConfigured() {
        return isFirebaseInitialized;
    }

    /**
     * Dispatches push notifications to active device tokens for the given users.
     * Guaranteed to never throw an exception to callers.
     */
    public void sendPushNotification(
            List<DeviceToken> deviceTokens,
            NotificationType type,
            NotificationPriority priority,
            String title,
            String body,
            Map<String, String> dataPayload
    ) {
        if (deviceTokens == null || deviceTokens.isEmpty()) {
            return;
        }

        List<String> tokens = deviceTokens.stream()
                .filter(DeviceToken::getIsActive)
                .map(DeviceToken::getDeviceToken)
                .distinct()
                .toList();

        if (tokens.isEmpty()) {
            return;
        }

        if (!isFirebaseInitialized) {
            log.debug("[FCM-Mock] Dispatching {} alert '{}' to {} active token(s)", type, title, tokens.size());
            return;
        }

        try {
            // 1. Resolve card preview styling & grouping
            NotificationType effectiveType = type != null ? type : NotificationType.SYSTEM;
            String groupKey = switch (effectiveType) {
                case LOW_STOCK, OUT_OF_STOCK, EXPIRING_SOON, EXPIRY_REMINDER, EXPIRED -> "homestock_group_stock_expiry";
                case SMART_RESTOCK_SUGGESTION, WEEKLY_INSIGHT, MONTHLY_REPORT -> "homestock_group_insights";
                default -> "homestock_group_activity";
            };

            String groupTitle = switch (groupKey) {
                case "homestock_group_stock_expiry" -> "Stock & Expiry Alerts";
                case "homestock_group_insights" -> "Smart Insights & Digests";
                default -> "Household Activity";
            };

            String badge = switch (effectiveType) {
                case OUT_OF_STOCK -> "🔴 OUT OF STOCK";
                case LOW_STOCK -> "⚠️ LOW STOCK";
                case EXPIRING_SOON, EXPIRY_REMINDER -> "⏳ EXPIRING SOON";
                case EXPIRED -> "⏰ EXPIRED";
                case SHOPPING_LIST_UPDATE -> "🛒 SHOPPING LIST";
                case STOCK_UPDATED, PURCHASE_RECORDED -> "✓ RESTOCKED";
                case SMART_RESTOCK_SUGGESTION -> "✨ SMART INSIGHT";
                case WEEKLY_INSIGHT, MONTHLY_REPORT -> "📊 INSIGHTS";
                case SYNC_COMPLETED -> "☁️ SYNCED";
                default -> "🏠 HOUSEHOLD";
            };

            String colorHex = switch (effectiveType) {
                case OUT_OF_STOCK, EXPIRED -> "#DC2626";
                case LOW_STOCK -> "#D97706";
                case EXPIRING_SOON, EXPIRY_REMINDER -> "#EA580C";
                case SHOPPING_LIST_UPDATE -> "#7C3AED";
                case STOCK_UPDATED, PURCHASE_RECORDED, SYNC_COMPLETED -> "#16A34A";
                case SMART_RESTOCK_SUGGESTION, WEEKLY_INSIGHT, MONTHLY_REPORT -> "#6366F1";
                default -> "#0284C7";
            };

            String actionLabel = switch (effectiveType) {
                case OUT_OF_STOCK, LOW_STOCK, SMART_RESTOCK_SUGGESTION -> "+ Add to Shopping";
                case EXPIRING_SOON, EXPIRY_REMINDER, EXPIRED -> "Inspect Item";
                case SHOPPING_LIST_UPDATE -> "View Shopping List";
                case STOCK_UPDATED, PURCHASE_RECORDED -> "View Item";
                case WEEKLY_INSIGHT, MONTHLY_REPORT -> "View Insights";
                default -> "Open HomeStock";
            };

            String lower = ((title != null ? title : "") + " " + (body != null ? body : "")).toLowerCase();
            String emoji = "📦";
            if (lower.contains("milk") || lower.contains("பால்")) emoji = "🥛";
            else if (lower.contains("egg") || lower.contains("முட்டை")) emoji = "🥚";
            else if (lower.contains("onion") || lower.contains("வெங்காயம்")) emoji = "🧅";
            else if (lower.contains("rice") || lower.contains("அரிசி")) emoji = "🍚";
            else if (lower.contains("cheese")) emoji = "🧀";
            else if (lower.contains("bread") || lower.contains("ரொட்டி")) emoji = "🍞";
            else if (lower.contains("oil") || lower.contains("எண்ணெய்")) emoji = "🌻";
            else if (lower.contains("atta") || lower.contains("flour") || lower.contains("மாவு")) emoji = "🌾";
            else if (lower.contains("tomato") || lower.contains("தக்காளி")) emoji = "🍅";
            else if (lower.contains("apple") || lower.contains("fruit")) emoji = "🍎";
            else if (lower.contains("banana")) emoji = "🍌";
            else if (lower.contains("coffee") || lower.contains("tea")) emoji = "☕";
            else if (lower.contains("soap") || lower.contains("detergent")) emoji = "🧼";
            else if (effectiveType == NotificationType.SHOPPING_LIST_UPDATE) emoji = "🛒";
            else if (effectiveType == NotificationType.SMART_RESTOCK_SUGGESTION) emoji = "✨";
            else if (effectiveType == NotificationType.SYNC_COMPLETED) emoji = "☁️";
            else if (effectiveType == NotificationType.STOCK_UPDATED) emoji = "✓";

            String formattedTitle = emoji + " " + (title != null ? title : "HomeStock Alert");

            // Build FCM MulticastMessage
            com.google.firebase.messaging.Notification fcmNotification = null;
            if (title != null && !title.isBlank()) {
                fcmNotification = com.google.firebase.messaging.Notification.builder()
                        .setTitle(formattedTitle)
                        .setBody(body != null ? body : "")
                        .build();
            }

            MulticastMessage.Builder messageBuilder = MulticastMessage.builder()
                    .addAllTokens(tokens)
                    .putData("type", effectiveType.name())
                    .putData("priority", priority != null ? priority.name() : "MEDIUM")
                    .putData("groupKey", groupKey)
                    .putData("groupTitle", groupTitle)
                    .putData("badge", badge)
                    .putData("emoji", emoji)
                    .putData("accentColor", colorHex)
                    .putData("actionLabel", actionLabel);

            if (title != null && !title.isBlank()) {
                messageBuilder.putData("title", title);
            }
            if (body != null && !body.isBlank()) {
                messageBuilder.putData("body", body);
            }

            if (fcmNotification != null) {
                messageBuilder.setNotification(fcmNotification);
            }

            if (dataPayload != null) {
                for (Map.Entry<String, String> entry : dataPayload.entrySet()) {
                    if (entry.getValue() != null) {
                        messageBuilder.putData(entry.getKey(), entry.getValue());
                    }
                }
            }

            // Android specific priority & channel configuration
            String channelId = switch (priority != null ? priority : NotificationPriority.MEDIUM) {
                case CRITICAL, HIGH -> "home_stock_important";
                case MEDIUM -> "home_stock_general";
                case LOW -> "home_stock_insights";
            };

            com.google.firebase.messaging.AndroidConfig.Priority androidPriority =
                    (priority == NotificationPriority.CRITICAL || priority == NotificationPriority.HIGH)
                            ? com.google.firebase.messaging.AndroidConfig.Priority.HIGH
                            : com.google.firebase.messaging.AndroidConfig.Priority.NORMAL;

            com.google.firebase.messaging.AndroidConfig androidConfig = com.google.firebase.messaging.AndroidConfig.builder()
                    .setPriority(androidPriority)
                    .setNotification(com.google.firebase.messaging.AndroidNotification.builder()
                            .setChannelId(channelId)
                            .setSound("default")
                            .setDefaultSound(true)
                            .setDefaultVibrateTimings(true)
                            .setColor(colorHex)
                            .setTag(groupKey)
                            .setClickAction("FLUTTER_NOTIFICATION_CLICK")
                            .build())
                    .build();

            messageBuilder.setAndroidConfig(androidConfig);

            // iOS / APNs configuration
            com.google.firebase.messaging.ApnsConfig apnsConfig = com.google.firebase.messaging.ApnsConfig.builder()
                    .setAps(com.google.firebase.messaging.Aps.builder()
                            .setSound("default")
                            .setContentAvailable(true)
                            .build())
                    .build();

            messageBuilder.setApnsConfig(apnsConfig);

            BatchResponse response = FirebaseMessaging.getInstance().sendEachForMulticast(messageBuilder.build());
            log.info("FCM push sent: {} success, {} failure(s)", response.getSuccessCount(), response.getFailureCount());

            // Deactivate invalid/unregistered tokens
            if (response.getFailureCount() > 0) {
                List<SendResponse> responses = response.getResponses();
                for (int i = 0; i < responses.size(); i++) {
                    SendResponse res = responses.get(i);
                    if (!res.isSuccessful()) {
                        String failedToken = tokens.get(i);
                        String errorCode = res.getException() != null ? res.getException().getMessagingErrorCode().name() : "UNKNOWN";
                        log.warn("FCM error for device token [prefix {}...]: {}", failedToken.substring(0, Math.min(10, failedToken.length())), errorCode);
                        if ("UNREGISTERED".equalsIgnoreCase(errorCode) || "INVALID_ARGUMENT".equalsIgnoreCase(errorCode)) {
                            deviceTokenRepository.deactivateToken(failedToken);
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.error("Failed to send FCM push notification (non-fatal): {}", e.getMessage());
        }
    }
}

