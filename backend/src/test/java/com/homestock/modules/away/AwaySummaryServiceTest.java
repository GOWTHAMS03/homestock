package com.homestock.modules.away;

import com.homestock.modules.away.dto.AwaySummaryResponseDto;
import com.homestock.modules.away.entity.AwayPeriodSummary;
import com.homestock.modules.away.entity.AwayPrediction;
import com.homestock.modules.away.entity.AwayPredictionType;
import com.homestock.modules.away.entity.PredictionStatus;
import com.homestock.modules.away.repository.AwayPeriodSummaryRepository;
import com.homestock.modules.away.repository.AwayPredictionRepository;
import com.homestock.modules.away.repository.UserActivityLogRepository;
import com.homestock.modules.away.service.*;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.shopping.entity.ShoppingList;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.shopping.repository.ShoppingListRepository;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
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
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AwaySummaryServiceTest {

    @Mock
    private AwayPeriodDetector awayPeriodDetector;

    @Mock
    private ConsumptionHistoryService consumptionHistoryService;

    @Mock
    private InventoryPredictionService inventoryPredictionService;

    @Mock
    private ExpiryPredictionService expiryPredictionService;

    @Mock
    private RestockPredictionService restockPredictionService;

    @Mock
    private AwayPeriodSummaryRepository summaryRepository;

    @Mock
    private AwayPredictionRepository predictionRepository;

    @Mock
    private UserActivityLogRepository activityLogRepository;

    @Mock
    private InventoryItemRepository inventoryItemRepository;

    @Mock
    private ShoppingListRepository shoppingListRepository;

    @Mock
    private ShoppingListItemRepository shoppingListItemRepository;

    @Mock
    private HomeRepository homeRepository;

    @Mock
    private UserRepository userRepository;

    private AwaySummaryService summaryService;

    private User testUser;
    private Home testHome;
    private UUID userId;
    private UUID homeId;

    @BeforeEach
    void setUp() {
        summaryService = new AwaySummaryService(
                awayPeriodDetector,
                consumptionHistoryService,
                inventoryPredictionService,
                expiryPredictionService,
                restockPredictionService,
                summaryRepository,
                predictionRepository,
                activityLogRepository,
                inventoryItemRepository,
                shoppingListRepository,
                shoppingListItemRepository,
                homeRepository,
                userRepository
        );
        ReflectionTestUtils.setField(summaryService, "maxSummaryItems", 5);

        userId = UUID.randomUUID();
        homeId = UUID.randomUUID();

        testUser = User.builder().fullName("Gowtham").email("user@homestock.app").build();
        ReflectionTestUtils.setField(testUser, "id", userId);

        testHome = Home.builder().name("Sekar Home").build();
        ReflectionTestUtils.setField(testHome, "id", homeId);

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(homeRepository.findById(homeId)).thenReturn(Optional.of(testHome));
    }

    @Test
    @DisplayName("Short inactivity returns isAway = false and zero important changes")
    void testNotAwaySummary() {
        AwayPeriodDetector.DetectionResult notAway = AwayPeriodDetector.DetectionResult.builder()
                .isAway(false)
                .awayDays(1)
                .lastMeaningfulActivityDate(Instant.now().minus(1, ChronoUnit.DAYS))
                .returnDate(Instant.now())
                .familyActivityDuringAway(List.of())
                .build();

        when(awayPeriodDetector.detectInactivity(userId, homeId)).thenReturn(notAway);

        AwaySummaryResponseDto response = summaryService.getAwaySummary(userId, homeId);

        assertNotNull(response);
        assertFalse(response.getIsAway());
        assertEquals(1, response.getAwayDays());
        assertEquals(0, response.getSummary().getImportantChanges());
    }

    @Test
    @DisplayName("6 days away generates summary ranking LIKELY_RAN_OUT and LIKELY_LOW items")
    void testAwaySummaryGeneration() {
        Instant sixDaysAgo = Instant.now().minus(6, ChronoUnit.DAYS);
        AwayPeriodDetector.DetectionResult away = AwayPeriodDetector.DetectionResult.builder()
                .isAway(true)
                .awayDays(6)
                .lastMeaningfulActivityDate(sixDaysAgo)
                .returnDate(Instant.now())
                .familyActivityDuringAway(List.of())
                .build();

        when(awayPeriodDetector.detectInactivity(userId, homeId)).thenReturn(away);
        when(summaryRepository.findRecentSummary(any(), any(), any())).thenReturn(Optional.empty());

        InventoryItem bread = InventoryItem.builder().name("Bread").quantity(new BigDecimal("2.0")).unit("packs").build();
        ReflectionTestUtils.setField(bread, "id", UUID.randomUUID());

        InventoryItem milk = InventoryItem.builder().name("Milk").quantity(new BigDecimal("2.0")).unit("L").build();
        ReflectionTestUtils.setField(milk, "id", UUID.randomUUID());

        when(inventoryItemRepository.findAllByHomeIdAndIsArchivedFalseOrderByNameAsc(homeId))
                .thenReturn(List.of(bread, milk));

        when(consumptionHistoryService.getItemHistoryBeforeAway(any(), any(), any(), any()))
                .thenReturn(ConsumptionHistoryService.ItemBaselineHistory.builder()
                        .stockBeforeAway(new BigDecimal("2.0"))
                        .knownPurchasesDuringAway(BigDecimal.ZERO)
                        .baselineDailyConsumption(new BigDecimal("0.35"))
                        .averagePurchaseInterval(new BigDecimal("3.0"))
                        .sampleCount(6)
                        .feedbackCalibrationFactor(BigDecimal.ONE)
                        .build());

        // Bread -> LIKELY_RAN_OUT
        when(inventoryPredictionService.predictInventoryChange(any(), any(), any(), any()))
                .thenReturn(InventoryPredictionService.InventoryPredictionResult.builder()
                        .predictionType(AwayPredictionType.LIKELY_RAN_OUT)
                        .stockBeforeAway(new BigDecimal("2.0"))
                        .estimatedQuantity(BigDecimal.ZERO)
                        .estimatedConsumed(new BigDecimal("3.0"))
                        .confidence(0.91)
                        .confidenceLabel("91% confidence")
                        .reason("Based on average consumption")
                        .displayTitle("Probably ran out")
                        .displaySubtitle("Based on your usual usage")
                        .actionLabel("Add to Shopping List")
                        .isProminent(true)
                        .build());

        when(expiryPredictionService.evaluateExpiryRisk(any(), any(), any())).thenReturn(Optional.empty());
        when(restockPredictionService.evaluateRestockCycle(any(), any(), anyLong(), any())).thenReturn(Optional.empty());

        when(summaryRepository.save(any())).thenAnswer(invocation -> {
            AwayPeriodSummary s = invocation.getArgument(0);
            ReflectionTestUtils.setField(s, "id", UUID.randomUUID());
            return s;
        });

        when(predictionRepository.findBySummaryIdOrderByConfidenceDesc(any()))
                .thenReturn(List.of(
                        AwayPrediction.builder()
                                .inventoryItem(bread)
                                .itemName("Bread")
                                .predictionType(AwayPredictionType.LIKELY_RAN_OUT)
                                .estimatedQuantity(BigDecimal.ZERO)
                                .estimatedConsumed(new BigDecimal("3.0"))
                                .unit("packs")
                                .confidence(new BigDecimal("0.91"))
                                .status(PredictionStatus.PENDING)
                                .isTopPriority(true)
                                .build()
                ));

        AwaySummaryResponseDto response = summaryService.getAwaySummary(userId, homeId);

        assertNotNull(response);
        assertTrue(response.getIsAway());
        assertEquals(6, response.getAwayDays());
        assertFalse(response.getTopPredictions().isEmpty());
        assertEquals("Bread", response.getTopPredictions().getFirst().getItemName());
        assertEquals(AwayPredictionType.LIKELY_RAN_OUT, response.getTopPredictions().getFirst().getType());
    }

    @Test
    @DisplayName("1-tap add to shopping list adds predicted items successfully")
    void testAddToShoppingList() {
        ShoppingList defaultList = ShoppingList.builder().home(testHome).name("Default List").build();
        ReflectionTestUtils.setField(defaultList, "id", UUID.randomUUID());

        when(shoppingListRepository.findByHomeIdAndIsDefaultTrue(homeId)).thenReturn(Optional.of(defaultList));

        InventoryItem milk = InventoryItem.builder().name("Milk").quantity(new BigDecimal("0.2")).unit("L").build();
        ReflectionTestUtils.setField(milk, "id", UUID.randomUUID());

        AwayPrediction pred = AwayPrediction.builder()
                .inventoryItem(milk)
                .itemName("Milk")
                .predictionType(AwayPredictionType.LIKELY_LOW)
                .build();
        ReflectionTestUtils.setField(pred, "id", UUID.randomUUID());

        when(predictionRepository.findAllById(any())).thenReturn(List.of(pred));
        when(shoppingListItemRepository.findActiveItemByHomeIdAndInventoryItemId(eq(homeId), eq(milk.getId())))
                .thenReturn(Optional.empty());

        int count = summaryService.addPredictedItemsToShoppingList(userId, homeId, List.of(pred.getId()));

        assertEquals(1, count);
    }
}
