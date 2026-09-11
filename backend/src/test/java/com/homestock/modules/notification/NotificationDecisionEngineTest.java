package com.homestock.modules.notification;

import com.homestock.modules.home.entity.Home;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.notification.composer.NotificationComposer;
import com.homestock.modules.notification.dto.NotificationCandidate;
import com.homestock.modules.notification.dto.NotificationDecision;
import com.homestock.modules.notification.engine.NotificationDecisionEngine;
import com.homestock.modules.notification.engine.NotificationDeduplicationService;
import com.homestock.modules.notification.entity.*;
import com.homestock.modules.notification.ml.NotificationFatigueService;
import com.homestock.modules.notification.ml.NotificationScoringService;
import com.homestock.modules.notification.ml.NotificationTimingService;
import com.homestock.modules.notification.repository.NotificationPreferenceRepository;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.user.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalTime;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class NotificationDecisionEngineTest {

    @Mock
    private NotificationPreferenceRepository preferenceRepository;

    @Mock
    private ShoppingListItemRepository shoppingListItemRepository;

    @Mock
    private NotificationDeduplicationService deduplicationService;

    @Mock
    private NotificationFatigueService fatigueService;

    private NotificationScoringService scoringService;
    private NotificationTimingService timingService;
    private NotificationComposer composer;
    private NotificationDecisionEngine decisionEngine;

    private User testUser;
    private Home testHome;
    private InventoryItem testOil;

    @BeforeEach
    void setUp() {
        scoringService = new NotificationScoringService();
        composer = new NotificationComposer();
        // Timing service mock or standalone
        NotificationTimingService mockTiming = org.mockito.Mockito.mock(NotificationTimingService.class);
        when(mockTiming.determineDeliveryTime(any(), any())).thenReturn(
                new NotificationTimingService.TimingRecommendation(true, Instant.now(), "Immediate delivery")
        );

        decisionEngine = new NotificationDecisionEngine(
                preferenceRepository,
                shoppingListItemRepository,
                deduplicationService,
                fatigueService,
                scoringService,
                mockTiming,
                composer
        );

        testUser = User.builder().email("user@homestock.app").fullName("Gowtham").build();
        ReflectionTestUtils.setField(testUser, "id", UUID.randomUUID());

        testHome = Home.builder().name("My Home").build();
        ReflectionTestUtils.setField(testHome, "id", UUID.randomUUID());

        testOil = InventoryItem.builder().name("Sunflower Oil").quantity(new BigDecimal("0.3")).unit("L").build();
        ReflectionTestUtils.setField(testOil, "id", UUID.randomUUID());
    }

    @Test
    @DisplayName("Scenario 1: High relevance low stock candidate produces SEND_NOW decision")
    void testLowStockSendNow() {
        NotificationCandidate candidate = NotificationCandidate.builder()
                .home(testHome)
                .recipientUser(testUser)
                .inventoryItem(testOil)
                .type(NotificationType.LOW_STOCK)
                .basePriority(NotificationPriority.HIGH)
                .currentStock(new BigDecimal("0.3"))
                .probabilityWithin3Days(0.85)
                .confidence("HIGH")
                .build();

        when(preferenceRepository.findByUserId(any())).thenReturn(Optional.empty());
        when(shoppingListItemRepository.findActiveItemByHomeIdAndInventoryItemId(any(), any())).thenReturn(Optional.empty());
        when(deduplicationService.isDuplicate(any(), any())).thenReturn(
                new NotificationDeduplicationService.DeduplicationCheck(false, "key", "Fresh alert")
        );
        when(fatigueService.calculateFatigue(any())).thenReturn(
                new NotificationFatigueService.FatigueAssessment(0.10, false, false, "Low fatigue")
        );

        NotificationDecision decision = decisionEngine.evaluateCandidate(candidate);

        assertNotNull(decision);
        assertEquals(NotificationDecisionType.SEND_NOW, decision.getDecisionType());
        assertEquals(NotificationChannel.PUSH, decision.getChannel());
        assertTrue(decision.getFinalTitle().contains("Sunflower Oil"));
        assertEquals("Add to List", decision.getActionLabel());
    }

    @Test
    @DisplayName("Scenario 2: Low stock item already on shopping list (offline synced) is SUPPRESSED")
    void testItemAlreadyOnShoppingListSuppressed() {
        NotificationCandidate candidate = NotificationCandidate.builder()
                .home(testHome)
                .recipientUser(testUser)
                .inventoryItem(testOil)
                .type(NotificationType.LOW_STOCK)
                .basePriority(NotificationPriority.HIGH)
                .build();

        when(preferenceRepository.findByUserId(any())).thenReturn(Optional.empty());
        // User already added oil to shopping list
        when(shoppingListItemRepository.findActiveItemByHomeIdAndInventoryItemId(any(), any()))
                .thenReturn(Optional.of(ShoppingListItem.builder().itemName("Sunflower Oil").build()));

        NotificationDecision decision = decisionEngine.evaluateCandidate(candidate);

        assertNotNull(decision);
        assertEquals(NotificationDecisionType.SUPPRESS, decision.getDecisionType());
        assertTrue(decision.getRationale().toLowerCase().contains("already present on the household shopping list"));
    }

    @Test
    @DisplayName("Scenario 3: Duplicate candidate within cooldown is SUPPRESSED")
    void testDuplicateCandidateSuppressed() {
        NotificationCandidate candidate = NotificationCandidate.builder()
                .home(testHome)
                .recipientUser(testUser)
                .inventoryItem(testOil)
                .type(NotificationType.LOW_STOCK)
                .basePriority(NotificationPriority.MEDIUM)
                .build();

        when(preferenceRepository.findByUserId(any())).thenReturn(Optional.empty());
        when(shoppingListItemRepository.findActiveItemByHomeIdAndInventoryItemId(any(), any())).thenReturn(Optional.empty());
        when(deduplicationService.isDuplicate(any(), any())).thenReturn(
                new NotificationDeduplicationService.DeduplicationCheck(true, "dedup:key", "Duplicate alert within 24h")
        );

        NotificationDecision decision = decisionEngine.evaluateCandidate(candidate);

        assertNotNull(decision);
        assertEquals(NotificationDecisionType.SUPPRESS, decision.getDecisionType());
        assertTrue(decision.getRationale().toLowerCase().contains("duplicate"));
    }

    @Test
    @DisplayName("Scenario 5: Critical alert is ALLOWED even when daily push limit is exceeded")
    void testCriticalNotificationBypassesDailyLimit() {
        NotificationCandidate criticalCandidate = NotificationCandidate.builder()
                .home(testHome)
                .recipientUser(testUser)
                .inventoryItem(testOil)
                .type(NotificationType.OUT_OF_STOCK)
                .basePriority(NotificationPriority.CRITICAL)
                .currentStock(BigDecimal.ZERO)
                .confidence("HIGH")
                .build();

        when(preferenceRepository.findByUserId(any())).thenReturn(Optional.empty());
        when(deduplicationService.isDuplicate(any(), any())).thenReturn(
                new NotificationDeduplicationService.DeduplicationCheck(false, "key", "Allowed")
        );
        // Daily push exceeded!
        when(fatigueService.calculateFatigue(any())).thenReturn(
                new NotificationFatigueService.FatigueAssessment(0.95, true, true, "Max daily push reached")
        );

        NotificationDecision decision = decisionEngine.evaluateCandidate(criticalCandidate);

        assertNotNull(decision);
        // Critical alerts retain PUSH channel and SEND_NOW decision
        assertEquals(NotificationChannel.PUSH, decision.getChannel());
        assertEquals(NotificationDecisionType.SEND_NOW, decision.getDecisionType());
        assertTrue(decision.getFinalTitle().contains("out of stock"));
    }

    @Test
    @DisplayName("Scenario 8: Family member already acted on item suppresses redundant low-stock alert")
    void testFamilyMemberActionSuppressesNotification() {
        User dad = User.builder().fullName("Dad").build();
        ReflectionTestUtils.setField(dad, "id", UUID.randomUUID());

        NotificationCandidate candidate = NotificationCandidate.builder()
                .home(testHome)
                .recipientUser(testUser) // Mom is recipient
                .triggerUser(dad)        // Dad bought or updated the stock
                .inventoryItem(testOil)
                .type(NotificationType.LOW_STOCK)
                .basePriority(NotificationPriority.MEDIUM)
                .build();

        when(preferenceRepository.findByUserId(any())).thenReturn(Optional.empty());

        NotificationDecision decision = decisionEngine.evaluateCandidate(candidate);

        assertNotNull(decision);
        assertEquals(NotificationDecisionType.SUPPRESS, decision.getDecisionType());
        assertTrue(decision.getRationale().toLowerCase().contains("family member recently acted"));
    }

    @Test
    @DisplayName("Scenario 10: High fatigue downgrades non-critical alert to IN_APP_ONLY")
    void testHighFatigueDowngradesToInApp() {
        NotificationCandidate candidate = NotificationCandidate.builder()
                .home(testHome)
                .recipientUser(testUser)
                .inventoryItem(testOil)
                .type(NotificationType.LOW_STOCK)
                .basePriority(NotificationPriority.HIGH)
                .currentStock(new BigDecimal("0.4"))
                .probabilityWithin3Days(0.80)
                .confidence("HIGH")
                .build();

        when(preferenceRepository.findByUserId(any())).thenReturn(Optional.empty());
        when(shoppingListItemRepository.findActiveItemByHomeIdAndInventoryItemId(any(), any())).thenReturn(Optional.empty());
        when(deduplicationService.isDuplicate(any(), any())).thenReturn(
                new NotificationDeduplicationService.DeduplicationCheck(false, "key", "Fresh")
        );
        // Daily push exceeded for non-critical item
        when(fatigueService.calculateFatigue(any())).thenReturn(
                new NotificationFatigueService.FatigueAssessment(0.85, true, false, "Push limit exceeded")
        );

        NotificationDecision decision = decisionEngine.evaluateCandidate(candidate);

        assertNotNull(decision);
        assertEquals(NotificationChannel.IN_APP, decision.getChannel());
        assertEquals(NotificationDecisionType.IN_APP_ONLY, decision.getDecisionType());
    }
}
