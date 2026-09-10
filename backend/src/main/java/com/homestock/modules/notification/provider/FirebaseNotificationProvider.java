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
            // Build FCM MulticastMessage
            com.google.firebase.messaging.Notification fcmNotification = com.google.firebase.messaging.Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .build();

            MulticastMessage.Builder messageBuilder = MulticastMessage.builder()
                    .addAllTokens(tokens)
                    .setNotification(fcmNotification)
                    .putData("type", type.name())
                    .putData("priority", priority.name());

            if (dataPayload != null) {
                for (Map.Entry<String, String> entry : dataPayload.entrySet()) {
                    if (entry.getValue() != null) {
                        messageBuilder.putData(entry.getKey(), entry.getValue());
                    }
                }
            }

            // Android specific priority & channel configuration
            String channelId = switch (priority) {
                case HIGH -> "home_stock_important";
                case MEDIUM -> "home_stock_general";
                case LOW -> "home_stock_insights";
            };

            com.google.firebase.messaging.AndroidConfig.Priority androidPriority =
                    (priority == NotificationPriority.HIGH)
                            ? com.google.firebase.messaging.AndroidConfig.Priority.HIGH
                            : com.google.firebase.messaging.AndroidConfig.Priority.NORMAL;

            com.google.firebase.messaging.AndroidConfig androidConfig = com.google.firebase.messaging.AndroidConfig.builder()
                    .setPriority(androidPriority)
                    .setNotification(com.google.firebase.messaging.AndroidNotification.builder()
                            .setChannelId(channelId)
                            .setSound("default")
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

