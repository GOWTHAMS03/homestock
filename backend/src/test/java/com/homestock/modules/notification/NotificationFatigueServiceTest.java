package com.homestock.modules.notification;

import com.homestock.modules.notification.entity.NotificationEventType;
import com.homestock.modules.notification.ml.NotificationFatigueService;
import com.homestock.modules.notification.repository.NotificationEventRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NotificationFatigueServiceTest {

    @Mock
    private NotificationEventRepository eventRepository;

    private NotificationFatigueService fatigueService;

    @BeforeEach
    void setUp() {
        fatigueService = new NotificationFatigueService(eventRepository);
        fatigueService.setMaxPushPerDay(5);
        fatigueService.setMaxNotificationsPerHour(2);
    }

    @Test
    @DisplayName("Normal activity should report low fatigue and no limit violations")
    void testLowFatigue() {
        UUID userId = UUID.randomUUID();
        when(eventRepository.countTotalByUserIdSince(eq(userId), any(Instant.class))).thenReturn(0L);
        when(eventRepository.countPushSentByUserIdSince(eq(userId), any(Instant.class))).thenReturn(1L);

        var assessment = fatigueService.calculateFatigue(userId);

        assertNotNull(assessment);
        assertFalse(assessment.isDailyPushExceeded());
        assertFalse(assessment.isHourlyExceeded());
        assertTrue(assessment.fatigueScore() < 0.25);
    }

    @Test
    @DisplayName("Hourly surge should trigger hourlyExceeded limit and elevate fatigue")
    void testHourlyBurstFatigue() {
        UUID userId = UUID.randomUUID();
        // 3 notifications in the past hour (exceeds limit of 2)
        when(eventRepository.countTotalByUserIdSince(eq(userId), any(Instant.class))).thenReturn(3L);
        when(eventRepository.countPushSentByUserIdSince(eq(userId), any(Instant.class))).thenReturn(3L);

        var assessment = fatigueService.calculateFatigue(userId);

        assertNotNull(assessment);
        assertTrue(assessment.isHourlyExceeded());
        assertTrue(assessment.fatigueScore() >= 0.60);
    }

    @Test
    @DisplayName("Daily push ceiling should trigger dailyPushExceeded limit")
    void testDailyPushExceeded() {
        UUID userId = UUID.randomUUID();
        when(eventRepository.countTotalByUserIdSince(eq(userId), any(Instant.class))).thenReturn(1L);
        // 6 push notifications sent in last 24h (exceeds limit of 5)
        when(eventRepository.countPushSentByUserIdSince(eq(userId), any(Instant.class))).thenReturn(6L);

        var assessment = fatigueService.calculateFatigue(userId);

        assertNotNull(assessment);
        assertTrue(assessment.isDailyPushExceeded());
        assertTrue(assessment.fatigueScore() >= 0.50);
    }
}
