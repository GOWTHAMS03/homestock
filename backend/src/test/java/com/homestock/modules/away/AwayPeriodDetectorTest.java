package com.homestock.modules.away;

import com.homestock.modules.away.repository.UserActivityLogRepository;
import com.homestock.modules.away.service.AwayPeriodDetector;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.entity.StockTransaction;
import com.homestock.modules.inventory.repository.StockTransactionRepository;
import com.homestock.modules.notification.repository.DeviceTokenRepository;
import com.homestock.modules.purchase.repository.PurchaseRepository;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.user.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AwayPeriodDetectorTest {

    @Mock
    private UserActivityLogRepository activityLogRepository;

    @Mock
    private StockTransactionRepository stockTransactionRepository;

    @Mock
    private PurchaseRepository purchaseRepository;

    @Mock
    private ShoppingListItemRepository shoppingListItemRepository;

    @Mock
    private DeviceTokenRepository deviceTokenRepository;

    private AwayPeriodDetector detector;

    private UUID userId;
    private UUID homeId;

    @BeforeEach
    void setUp() {
        detector = new AwayPeriodDetector(
                activityLogRepository,
                stockTransactionRepository,
                purchaseRepository,
                shoppingListItemRepository,
                deviceTokenRepository
        );
        ReflectionTestUtils.setField(detector, "minInactiveDays", 3);

        userId = UUID.randomUUID();
        homeId = UUID.randomUUID();
    }

    @Test
    @DisplayName("Short gap (< 3 days) returns isAway = false")
    void testShortInactivityNotAway() {
        Instant oneDayAgo = Instant.now().minus(1, ChronoUnit.DAYS);

        when(activityLogRepository.findLatestActivityByUserId(userId)).thenReturn(Optional.of(oneDayAgo));
        when(stockTransactionRepository.findLatestTransactionTimeByUserId(userId)).thenReturn(Optional.empty());
        when(purchaseRepository.findLatestPurchaseTimeByUserId(userId)).thenReturn(Optional.empty());
        when(shoppingListItemRepository.findLatestAddedTimeByUserId(userId)).thenReturn(Optional.empty());
        when(deviceTokenRepository.findLatestActivityByUserId(userId)).thenReturn(Optional.empty());

        AwayPeriodDetector.DetectionResult result = detector.detectInactivity(userId, homeId);

        assertNotNull(result);
        assertFalse(result.isAway(), "1 day gap should NOT be marked as away");
        assertEquals(1, result.getAwayDays());
    }

    @Test
    @DisplayName("Meaningful gap (6 days) returns isAway = true and calculates family events")
    void testMeaningfulInactivityIsAway() {
        Instant sixDaysAgo = Instant.now().minus(6, ChronoUnit.DAYS);

        when(activityLogRepository.findLatestActivityByUserId(userId)).thenReturn(Optional.of(sixDaysAgo));
        when(stockTransactionRepository.findLatestTransactionTimeByUserId(userId)).thenReturn(Optional.empty());
        when(purchaseRepository.findLatestPurchaseTimeByUserId(userId)).thenReturn(Optional.empty());
        when(shoppingListItemRepository.findLatestAddedTimeByUserId(userId)).thenReturn(Optional.empty());
        when(deviceTokenRepository.findLatestActivityByUserId(userId)).thenReturn(Optional.empty());

        // Family member action while away
        User dad = User.builder().fullName("Dad").build();
        InventoryItem milk = InventoryItem.builder().name("Milk").build();
        StockTransaction dadTx = StockTransaction.builder()
                .user(dad)
                .item(milk)
                .newQuantity(new BigDecimal("2.0"))
                .unit("L")
                .build();
        ReflectionTestUtils.setField(dadTx, "createdAt", Instant.now().minus(2, ChronoUnit.DAYS));

        when(stockTransactionRepository.findFamilyTransactionsSince(eq(homeId), eq(userId), any()))
                .thenReturn(List.of(dadTx));
        when(purchaseRepository.findFamilyPurchasesSince(eq(homeId), eq(userId), any()))
                .thenReturn(List.of());

        AwayPeriodDetector.DetectionResult result = detector.detectInactivity(userId, homeId);

        assertNotNull(result);
        assertTrue(result.isAway(), "6 days gap should be marked as away");
        assertEquals(6, result.getAwayDays());
        assertFalse(result.getFamilyActivityDuringAway().isEmpty());
        assertTrue(result.getFamilyActivityDuringAway().getFirst().contains("Dad updated Milk stock"));
    }

    @Test
    @DisplayName("Fresh user with no prior activity returns isAway = false")
    void testFreshUserNotAway() {
        when(activityLogRepository.findLatestActivityByUserId(userId)).thenReturn(Optional.empty());
        when(stockTransactionRepository.findLatestTransactionTimeByUserId(userId)).thenReturn(Optional.empty());
        when(purchaseRepository.findLatestPurchaseTimeByUserId(userId)).thenReturn(Optional.empty());
        when(shoppingListItemRepository.findLatestAddedTimeByUserId(userId)).thenReturn(Optional.empty());
        when(deviceTokenRepository.findLatestActivityByUserId(userId)).thenReturn(Optional.empty());

        AwayPeriodDetector.DetectionResult result = detector.detectInactivity(userId, homeId);

        assertNotNull(result);
        assertFalse(result.isAway());
        assertEquals(0, result.getAwayDays());
    }
}
