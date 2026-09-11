package com.homestock.modules.notification;

import com.homestock.modules.home.entity.Home;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.notification.dto.NotificationCandidate;
import com.homestock.modules.notification.engine.NotificationDeduplicationService;
import com.homestock.modules.notification.entity.NotificationDeduplication;
import com.homestock.modules.notification.entity.NotificationType;
import com.homestock.modules.notification.repository.NotificationDeduplicationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NotificationDeduplicationServiceTest {

    @Mock
    private NotificationDeduplicationRepository deduplicationRepository;

    private NotificationDeduplicationService deduplicationService;

    @BeforeEach
    void setUp() {
        deduplicationService = new NotificationDeduplicationService(deduplicationRepository);
    }

    @Test
    @DisplayName("Candidate with no prior notification is not a duplicate")
    void testNoPriorRecord() {
        when(deduplicationRepository.findByDedupKey(any())).thenReturn(Optional.empty());

        NotificationCandidate candidate = NotificationCandidate.builder()
                .type(NotificationType.LOW_STOCK)
                .home(Home.builder().build())
                .inventoryItem(InventoryItem.builder().name("Rice").build())
                .currentStock(new BigDecimal("1.0"))
                .build();

        var check = deduplicationService.isDuplicate(candidate, Duration.ofHours(24));

        assertFalse(check.isDuplicate());
    }

    @Test
    @DisplayName("Candidate sent recently with same quantity is suppressed as duplicate")
    void testDuplicateWithinCooldown() {
        NotificationDeduplication existing = NotificationDeduplication.builder()
                .dedupKey("LOW_STOCK:home1:item1:2026-09-11")
                .lastSentAt(Instant.now().minus(Duration.ofHours(2)))
                .lastQuantity(new BigDecimal("0.5"))
                .build();

        when(deduplicationRepository.findByDedupKey(any())).thenReturn(Optional.of(existing));

        NotificationCandidate candidate = NotificationCandidate.builder()
                .dedupKey("LOW_STOCK:home1:item1:2026-09-11")
                .type(NotificationType.LOW_STOCK)
                .currentStock(new BigDecimal("0.5"))
                .build();

        var check = deduplicationService.isDuplicate(candidate, Duration.ofHours(24));

        assertTrue(check.isDuplicate());
    }

    @Test
    @DisplayName("Stock dropping to zero bypasses cooldown suppression")
    void testZeroStockBypassesCooldown() {
        NotificationDeduplication existing = NotificationDeduplication.builder()
                .dedupKey("LOW_STOCK:home1:item1:2026-09-11")
                .lastSentAt(Instant.now().minus(Duration.ofHours(2)))
                .lastQuantity(new BigDecimal("0.5"))
                .build();

        when(deduplicationRepository.findByDedupKey(any())).thenReturn(Optional.of(existing));

        // Quantity has now dropped from 0.5 to 0.0
        NotificationCandidate candidate = NotificationCandidate.builder()
                .dedupKey("LOW_STOCK:home1:item1:2026-09-11")
                .type(NotificationType.OUT_OF_STOCK)
                .currentStock(BigDecimal.ZERO)
                .build();

        var check = deduplicationService.isDuplicate(candidate, Duration.ofHours(24));

        assertFalse(check.isDuplicate(), "Stock dropping to zero must not be suppressed");
    }
}
