package com.homestock.modules.notification;

import com.homestock.modules.notification.dto.NotificationCandidate;
import com.homestock.modules.notification.entity.NotificationPreference;
import com.homestock.modules.notification.entity.NotificationPriority;
import com.homestock.modules.notification.ml.NotificationTimingService;
import com.homestock.modules.notification.repository.NotificationEventRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalTime;
import java.util.Collections;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NotificationTimingServiceTest {

    @Mock
    private NotificationEventRepository eventRepository;

    private NotificationTimingService timingService;

    @BeforeEach
    void setUp() {
        timingService = new NotificationTimingService(eventRepository);
    }

    @Test
    @DisplayName("Critical notifications should send immediately when not in quiet hours")
    void testCriticalNotificationImmediate() {
        NotificationCandidate candidate = NotificationCandidate.builder()
                .basePriority(NotificationPriority.CRITICAL)
                .build();

        NotificationPreference preference = NotificationPreference.builder()
                .quietHoursEnabled(false)
                .build();

        var recommendation = timingService.determineDeliveryTime(candidate, preference);

        assertNotNull(recommendation);
        assertTrue(recommendation.sendImmediately());
        assertNotNull(recommendation.deliveryTimestamp());
    }

    @Test
    @DisplayName("Non-urgent notifications inside active quiet hours should be deferred")
    void testQuietHoursDeferral() {
        NotificationCandidate candidate = NotificationCandidate.builder()
                .basePriority(NotificationPriority.MEDIUM)
                .build();

        // Quiet hours 00:00 to 23:59 (covers current time)
        NotificationPreference preference = NotificationPreference.builder()
                .quietHoursEnabled(true)
                .quietHoursStart(LocalTime.of(0, 0))
                .quietHoursEnd(LocalTime.of(23, 59))
                .build();

        var recommendation = timingService.determineDeliveryTime(candidate, preference);

        assertNotNull(recommendation);
        assertFalse(recommendation.sendImmediately());
        assertTrue(recommendation.reason().toLowerCase().contains("quiet"));
    }

    @Test
    @DisplayName("Learned peak time falls back to 18:30 when insufficient historical data")
    void testDefaultPeakTimeFallback() {
        when(eventRepository.findPositiveInteractionsByUserId(any())).thenReturn(Collections.emptyList());

        LocalTime peak = timingService.getLearnedBestTime(UUID.randomUUID());

        assertNotNull(peak);
        assertEquals(18, peak.getHour());
        assertEquals(30, peak.getMinute());
    }
}
