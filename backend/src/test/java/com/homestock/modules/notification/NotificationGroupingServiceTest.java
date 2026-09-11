package com.homestock.modules.notification;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.notification.dto.NotificationCandidate;
import com.homestock.modules.notification.engine.NotificationGroupingService;
import com.homestock.modules.notification.entity.NotificationPriority;
import com.homestock.modules.notification.entity.NotificationType;
import com.homestock.modules.notification.repository.NotificationDigestRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class NotificationGroupingServiceTest {

    @Mock
    private NotificationDigestRepository digestRepository;

    private NotificationGroupingService groupingService;

    @BeforeEach
    void setUp() {
        groupingService = new NotificationGroupingService(digestRepository, new ObjectMapper());
    }

    @Test
    @DisplayName("Five low-stock products should be consolidated into a single digest alert")
    void testFiveLowStockProductsGrouped() {
        Home home = Home.builder().name("Sekar Home").build();
        ReflectionTestUtils_setId(home, UUID.randomUUID());

        List<NotificationCandidate> candidates = List.of(
                createLowStockCandidate(home, "Sunflower Oil"),
                createLowStockCandidate(home, "Basmati Rice"),
                createLowStockCandidate(home, "Toor Dal"),
                createLowStockCandidate(home, "Bathing Soap"),
                createLowStockCandidate(home, "Cow Milk")
        );

        List<NotificationCandidate> grouped = groupingService.processGrouping(home, candidates);

        assertNotNull(grouped);
        // Instead of 5 separate alerts, there is exactly 1 unified digest
        assertEquals(1, grouped.size());

        NotificationCandidate digest = grouped.get(0);
        assertTrue(digest.getProposedTitle().contains("5 items may run out soon"));
        assertTrue(digest.getProposedBody().contains("Estimated shopping cost"));
        assertTrue(digest.getProposedBody().contains("Sunflower Oil"));
        assertTrue(digest.getProposedBody().contains("Basmati Rice"));
    }

    @Test
    @DisplayName("Critical emergency alerts are preserved separately and never grouped")
    void testCriticalAlertsNotGrouped() {
        Home home = Home.builder().name("Sekar Home").build();
        ReflectionTestUtils_setId(home, UUID.randomUUID());

        NotificationCandidate criticalItem = NotificationCandidate.builder()
                .home(home)
                .inventoryItem(InventoryItem.builder().name("Baby Milk Formula").build())
                .type(NotificationType.OUT_OF_STOCK)
                .basePriority(NotificationPriority.CRITICAL)
                .proposedTitle("🚨 Baby Milk Formula is out of stock")
                .build();

        List<NotificationCandidate> candidates = List.of(
                createLowStockCandidate(home, "Oil"),
                createLowStockCandidate(home, "Rice"),
                createLowStockCandidate(home, "Dal"),
                criticalItem
        );

        List<NotificationCandidate> results = groupingService.processGrouping(home, candidates);

        // 3 low-stock items grouped into 1 digest + 1 critical alert = 2 candidates
        assertEquals(2, results.size());
        assertTrue(results.stream().anyMatch(c -> c.getBasePriority() == NotificationPriority.CRITICAL));
    }

    private NotificationCandidate createLowStockCandidate(Home home, String name) {
        return NotificationCandidate.builder()
                .home(home)
                .inventoryItem(InventoryItem.builder().name(name).build())
                .type(NotificationType.LOW_STOCK)
                .basePriority(NotificationPriority.HIGH)
                .currentStock(new BigDecimal("0.5"))
                .build();
    }

    private void ReflectionTestUtils_setId(Home home, UUID id) {
        org.springframework.test.util.ReflectionTestUtils.setField(home, "id", id);
    }
}
