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
        ObjectMapper objectMapper = new ObjectMapper();

        engine = new NotificationEngine(
                notificationRepository,
                deduplicationRepository,
                homeMemberRepository,
                preferenceService,
                deviceTokenService,
                firebaseProvider,
                objectMapper
        );

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
}

