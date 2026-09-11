package com.homestock.modules.notification;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.entity.HomeMember;
import com.homestock.modules.home.entity.HomeRole;
import com.homestock.modules.home.repository.HomeMemberRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.notification.entity.*;
import com.homestock.modules.notification.provider.FirebaseNotificationProvider;
import com.homestock.modules.notification.repository.NotificationDeduplicationRepository;
import com.homestock.modules.notification.repository.NotificationRepository;
import com.homestock.modules.notification.service.DeviceTokenService;
import com.homestock.modules.notification.service.NotificationEngine;
import com.homestock.modules.notification.service.NotificationPreferenceService;
import com.homestock.modules.user.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalTime;
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class NotificationEngineTest {

    private NotificationRepository notificationRepository;
    private NotificationDeduplicationRepository deduplicationRepository;
    private HomeMemberRepository homeMemberRepository;
    private NotificationPreferenceService preferenceService;
    private DeviceTokenService deviceTokenService;
    private FirebaseNotificationProvider firebaseProvider;
    private com.homestock.modules.notification.engine.NotificationDecisionEngine decisionEngine;
    private com.homestock.modules.notification.repository.NotificationEventRepository eventRepository;
    private com.homestock.modules.notification.engine.NotificationDeduplicationService deduplicationService;
    private com.homestock.modules.inventory.repository.InventoryItemRepository inventoryItemRepository;
    private NotificationEngine engine;

    private Home testHome;
    private User user1;
    private User user2;
    private InventoryItem testItem;
    private HomeMember member1;
    private HomeMember member2;

    @BeforeEach
    void setUp() {
        notificationRepository = mock(NotificationRepository.class);
        deduplicationRepository = mock(NotificationDeduplicationRepository.class);
        homeMemberRepository = mock(HomeMemberRepository.class);
        preferenceService = mock(NotificationPreferenceService.class);
        deviceTokenService = mock(DeviceTokenService.class);
        firebaseProvider = mock(FirebaseNotificationProvider.class);
        decisionEngine = mock(com.homestock.modules.notification.engine.NotificationDecisionEngine.class);
        eventRepository = mock(com.homestock.modules.notification.repository.NotificationEventRepository.class);
        deduplicationService = mock(com.homestock.modules.notification.engine.NotificationDeduplicationService.class);
        inventoryItemRepository = mock(com.homestock.modules.inventory.repository.InventoryItemRepository.class);
        ObjectMapper objectMapper = new ObjectMapper();

        engine = new NotificationEngine(
                notificationRepository,
                deduplicationRepository,
                homeMemberRepository,
                preferenceService,
                deviceTokenService,
                firebaseProvider,
                objectMapper,
                decisionEngine,
                eventRepository,
                deduplicationService,
                inventoryItemRepository
        );

        when(decisionEngine.evaluateCandidate(any())).thenAnswer(invocation -> {
            com.homestock.modules.notification.dto.NotificationCandidate c = invocation.getArgument(0);
            if (c == null) {
                return com.homestock.modules.notification.dto.NotificationDecision.builder()
                        .decisionType(com.homestock.modules.notification.entity.NotificationDecisionType.SEND_NOW)
                        .channel(com.homestock.modules.notification.entity.NotificationChannel.PUSH)
                        .resolvedPriority(NotificationPriority.MEDIUM)
                        .finalTitle("Test")
                        .finalBody("Test")
                        .build();
            }
            return com.homestock.modules.notification.dto.NotificationDecision.builder()
                    .candidate(c)
                    .decisionType(com.homestock.modules.notification.entity.NotificationDecisionType.SEND_NOW)
                    .channel(com.homestock.modules.notification.entity.NotificationChannel.PUSH)
                    .resolvedPriority(c.getBasePriority() != null ? c.getBasePriority() : NotificationPriority.MEDIUM)
                    .finalTitle(c.getProposedTitle())
                    .finalBody(c.getProposedBody())
                    .finalScore(BigDecimal.ONE)
                    .build();
        });

        user1 = User.builder()
                .email("user1@example.com")
                .fullName("User One")
                .build();
        user1.setId(UUID.randomUUID());

        user2 = User.builder()
                .email("user2@example.com")
                .fullName("User Two")
                .build();
        user2.setId(UUID.randomUUID());

        testHome = Home.builder()
                .name("Sweet Home")
                .build();
        testHome.setId(UUID.randomUUID());

        member1 = HomeMember.builder().home(testHome).user(user1).role(HomeRole.OWNER).build();
        member2 = HomeMember.builder().home(testHome).user(user2).role(HomeRole.MEMBER).build();

        testItem = InventoryItem.builder()
                .home(testHome)
                .name("Oat Milk")
                .quantity(BigDecimal.ZERO)
                .minimumQuantity(new BigDecimal("2.0"))
                .unit("liters")
                .build();
        testItem.setId(UUID.randomUUID());

        when(homeMemberRepository.findAllByHomeId(testHome.getId())).thenReturn(List.of(member1, member2));
        when(preferenceService.getOrCreatePreferences(any(User.class))).thenReturn(
                NotificationPreference.builder()
                        .outOfStockEnabled(true)
                        .lowStockEnabled(true)
                        .shoppingListEnabled(true)
                        .quietHoursEnabled(false)
                        .build()
        );
    }

    @Test
    @DisplayName("Quiet hours midnight-crossing check correctly flags bedtime")
    void testQuietHoursMidnightCrossing() {
        NotificationPreference pref = NotificationPreference.builder()
                .quietHoursEnabled(true)
                .quietHoursStart(LocalTime.of(22, 0))
                .quietHoursEnd(LocalTime.of(7, 0))
                .build();

        // 23:30 is during quiet hours
        assertThat(pref.isInsideQuietHours(LocalTime.of(23, 30))).isTrue();

        // 03:00 is during quiet hours
        assertThat(pref.isInsideQuietHours(LocalTime.of(3, 0))).isTrue();

        // 14:00 is outside quiet hours
        assertThat(pref.isInsideQuietHours(LocalTime.of(14, 0))).isFalse();
    }

    @Test
    @DisplayName("Out of stock alert dispatches to home members")
    void testOutOfStockAlert() {
        when(deduplicationRepository.findByDedupKey(anyString())).thenReturn(Optional.empty());
        when(notificationRepository.save(any(Notification.class))).thenAnswer(i -> i.getArgument(0));

        engine.notifyOutOfStock(testHome, testItem, null);

        ArgumentCaptor<Notification> notifCaptor = ArgumentCaptor.forClass(Notification.class);
        verify(notificationRepository, atLeastOnce()).save(notifCaptor.capture());

        Notification saved = notifCaptor.getValue();
        assertThat(saved.getType()).isEqualTo(NotificationType.OUT_OF_STOCK);
        assertThat(saved.getTitle()).contains("Oat Milk is out of stock");
        assertThat(saved.getPriority()).isEqualTo(NotificationPriority.CRITICAL);
    }

    @Test
    @DisplayName("Cooldown suppresses duplicate alerts within window")
    void testCooldownSuppression() {
        NotificationDeduplication activeCooldown = NotificationDeduplication.builder()
                .dedupKey("OUT_OF_STOCK:" + testHome.getId() + ":" + testItem.getId())
                .lastSentAt(Instant.now().minusSeconds(60)) // 1 minute ago
                .build();

        when(deduplicationRepository.findByDedupKey(anyString()))
                .thenReturn(Optional.of(activeCooldown));

        engine.notifyOutOfStock(testHome, testItem, null);

        // Since cooldown is 24 hours, this should be suppressed
        verify(notificationRepository, never()).save(any(Notification.class));
        verify(firebaseProvider, never()).sendPushNotification(any(), any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("Sync action excludes originating user from push alert")
    void testOriginatingUserExclusionOnSync() {
        when(deduplicationRepository.findByDedupKey(anyString())).thenReturn(Optional.empty());
        when(notificationRepository.save(any(Notification.class))).thenAnswer(i -> i.getArgument(0));

        // user1 updated the shopping list, so user1 should be excluded
        engine.notifyShoppingListUpdate(testHome, user1, List.of("Apples", "Bananas"));

        ArgumentCaptor<Notification> notifCaptor = ArgumentCaptor.forClass(Notification.class);
        verify(notificationRepository).save(notifCaptor.capture());

        // Target user must be user2, not user1
        assertThat(notifCaptor.getValue().getUser().getId()).isEqualTo(user2.getId());
    }

    @Test
    @DisplayName("notifyHomeChanged sends silent data-only push to OTHER members and never to actor")
    void testNotifyHomeChangedSendsSilentDataOnlyPushToOtherMembersOnly() {
        DeviceToken user2Token = DeviceToken.builder()
                .user(user2)
                .deviceToken("token-user2")
                .isActive(true)
                .build();

        when(deviceTokenService.getActiveTokensForUsers(List.of(user2.getId()))).thenReturn(List.of(user2Token));

        // user1 triggers sync
        engine.notifyHomeChanged(testHome, user1.getId());

        // Verify push sent ONLY to user2 and with NULL title and body (pure silent push!)
        ArgumentCaptor<String> titleCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> bodyCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<Map<String, String>> dataCaptor = ArgumentCaptor.forClass(Map.class);

        verify(firebaseProvider).sendPushNotification(
                eq(List.of(user2Token)),
                eq(NotificationType.SYSTEM),
                eq(NotificationPriority.LOW),
                titleCaptor.capture(),
                bodyCaptor.capture(),
                dataCaptor.capture()
        );

        assertThat(titleCaptor.getValue()).isNull();
        assertThat(bodyCaptor.getValue()).isNull();
        assertThat(dataCaptor.getValue().get("type")).isEqualTo("HOME_CHANGED");
        assertThat(dataCaptor.getValue().get("action")).isEqualTo("SYNC_HOME");
    }

    @Test
    @DisplayName("notifyHomeChanged sends NO push when single user syncs own home")
    void testNotifyHomeChangedDoesNotNotifySingleUserHousehold() {
        Home singleHome = Home.builder().name("Solo Home").build();
        singleHome.setId(UUID.randomUUID());
        HomeMember soloMember = HomeMember.builder().home(singleHome).user(user1).role(HomeRole.OWNER).build();

        when(homeMemberRepository.findAllByHomeId(singleHome.getId())).thenReturn(List.of(soloMember));

        // user1 is the only member and triggers sync
        engine.notifyHomeChanged(singleHome, user1.getId());

        // Zero push notifications sent
        verify(firebaseProvider, never()).sendPushNotification(any(), any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("Decision engine SUPPRESS decision prevents push and in-app persistence")
    void testDecisionEngineSuppressionPreventsPushAndPersistence() {
        when(deduplicationRepository.findByDedupKey(anyString())).thenReturn(Optional.empty());
        org.mockito.Mockito.doReturn(
                com.homestock.modules.notification.dto.NotificationDecision.builder()
                        .decisionType(com.homestock.modules.notification.entity.NotificationDecisionType.SUPPRESS)
                        .channel(com.homestock.modules.notification.entity.NotificationChannel.SILENT)
                        .rationale("Fatigue push limit exceeded")
                        .build()
        ).when(decisionEngine).evaluateCandidate(any());

        engine.notifyLowStock(testHome, testItem, null);

        // Neither saved to DB nor pushed to Firebase
        verify(notificationRepository, never()).save(any(Notification.class));
        verify(firebaseProvider, never()).sendPushNotification(any(), any(), any(), any(), any(), any());
    }
}

