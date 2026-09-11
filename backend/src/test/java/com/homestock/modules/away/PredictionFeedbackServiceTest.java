package com.homestock.modules.away;

import com.homestock.modules.away.entity.*;
import com.homestock.modules.away.repository.AwayPredictionRepository;
import com.homestock.modules.away.repository.PredictionFeedbackRepository;
import com.homestock.modules.away.service.PredictionFeedbackService;
import com.homestock.modules.consumption.entity.QuantitySource;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.inventory.repository.StockTransactionRepository;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class PredictionFeedbackServiceTest {

    @Mock
    private AwayPredictionRepository predictionRepository;

    @Mock
    private PredictionFeedbackRepository feedbackRepository;

    @Mock
    private InventoryItemRepository inventoryItemRepository;

    @Mock
    private StockTransactionRepository stockTransactionRepository;

    @Mock
    private UserRepository userRepository;

    private PredictionFeedbackService feedbackService;

    private User testUser;
    private Home testHome;
    private InventoryItem testMilk;
    private AwayPeriodSummary testSummary;
    private AwayPrediction testPrediction;

    @BeforeEach
    void setUp() {
        feedbackService = new PredictionFeedbackService(
                predictionRepository,
                feedbackRepository,
                inventoryItemRepository,
                stockTransactionRepository,
                userRepository
        );

        testUser = User.builder().email("user@homestock.app").fullName("Gowtham").build();
        ReflectionTestUtils.setField(testUser, "id", UUID.randomUUID());

        testHome = Home.builder().name("Sekar Home").build();
        ReflectionTestUtils.setField(testHome, "id", UUID.randomUUID());

        testMilk = InventoryItem.builder()
                .name("Cow Milk")
                .quantity(new BigDecimal("2.0"))
                .unit("L")
                .build();
        ReflectionTestUtils.setField(testMilk, "id", UUID.randomUUID());

        testSummary = AwayPeriodSummary.builder()
                .home(testHome)
                .user(testUser)
                .awayDays(6)
                .build();
        ReflectionTestUtils.setField(testSummary, "id", UUID.randomUUID());

        testPrediction = AwayPrediction.builder()
                .summary(testSummary)
                .inventoryItem(testMilk)
                .itemName("Cow Milk")
                .predictionType(AwayPredictionType.LIKELY_LOW)
                .stockBeforeAway(new BigDecimal("2.0"))
                .estimatedQuantity(new BigDecimal("0.25"))
                .estimatedConsumed(new BigDecimal("1.75"))
                .unit("L")
                .confidence(new BigDecimal("0.89"))
                .status(PredictionStatus.PENDING)
                .build();
        ReflectionTestUtils.setField(testPrediction, "id", UUID.randomUUID());
    }

    @Test
    @DisplayName("Accept prediction ('Looks right') updates inventory to estimated stock and marks ACCEPTED")
    void testAcceptPrediction() {
        when(predictionRepository.findById(testPrediction.getId())).thenReturn(Optional.of(testPrediction));
        when(userRepository.findById(testUser.getId())).thenReturn(Optional.of(testUser));

        AwayPrediction accepted = feedbackService.acceptPrediction(testPrediction.getId(), testUser.getId());

        assertNotNull(accepted);
        assertEquals(PredictionStatus.ACCEPTED, accepted.getStatus());

        // Verify inventory update
        ArgumentCaptor<InventoryItem> itemCaptor = ArgumentCaptor.forClass(InventoryItem.class);
        verify(inventoryItemRepository).save(itemCaptor.capture());
        InventoryItem savedItem = itemCaptor.getValue();
        assertEquals(new BigDecimal("0.25"), savedItem.getQuantity());
        assertEquals(QuantitySource.ESTIMATED, savedItem.getQuantitySource());

        // Verify feedback logged
        ArgumentCaptor<PredictionFeedback> feedbackCaptor = ArgumentCaptor.forClass(PredictionFeedback.class);
        verify(feedbackRepository).save(feedbackCaptor.capture());
        assertEquals(FeedbackSignalType.PREDICTION_ACCEPTED, feedbackCaptor.getValue().getFeedbackType());
        assertEquals(BigDecimal.ONE, feedbackCaptor.getValue().getLearningAdjustmentFactor());
    }

    @Test
    @DisplayName("Correct prediction ('Update stock') updates inventory to user verified count and calculates learning ratio")
    void testCorrectPrediction() {
        when(predictionRepository.findById(testPrediction.getId())).thenReturn(Optional.of(testPrediction));
        when(userRepository.findById(testUser.getId())).thenReturn(Optional.of(testUser));

        // User says actual remaining is 0.5L instead of AI predicted 0.25L
        BigDecimal userActualQty = new BigDecimal("0.50");
        AwayPrediction corrected = feedbackService.correctPrediction(testPrediction.getId(), userActualQty, testUser.getId());

        assertNotNull(corrected);
        assertEquals(PredictionStatus.CORRECTED, corrected.getStatus());

        // Verify inventory update
        ArgumentCaptor<InventoryItem> itemCaptor = ArgumentCaptor.forClass(InventoryItem.class);
        verify(inventoryItemRepository).save(itemCaptor.capture());
        assertEquals(userActualQty, itemCaptor.getValue().getQuantity());
        assertEquals(QuantitySource.VERIFIED, itemCaptor.getValue().getQuantitySource());

        // Verify feedback learning factor
        // stockBefore = 2.0, actual = 0.5 -> actual consumed = 1.5. predicted consumed = 1.75
        // ratio = 1.5 / 1.75 = 0.8571
        ArgumentCaptor<PredictionFeedback> feedbackCaptor = ArgumentCaptor.forClass(PredictionFeedback.class);
        verify(feedbackRepository).save(feedbackCaptor.capture());
        PredictionFeedback feedback = feedbackCaptor.getValue();
        assertEquals(FeedbackSignalType.PREDICTION_CORRECTED, feedback.getFeedbackType());
        assertTrue(feedback.getLearningAdjustmentFactor().compareTo(new BigDecimal("0.8500")) >= 0 &&
                feedback.getLearningAdjustmentFactor().compareTo(new BigDecimal("0.8600")) <= 0);
    }
}
