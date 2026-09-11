package com.homestock.modules.away.service;

import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.away.entity.AwayPrediction;
import com.homestock.modules.away.entity.FeedbackSignalType;
import com.homestock.modules.away.entity.PredictionFeedback;
import com.homestock.modules.away.entity.PredictionStatus;
import com.homestock.modules.away.repository.AwayPredictionRepository;
import com.homestock.modules.away.repository.PredictionFeedbackRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.entity.StockTransaction;
import com.homestock.modules.inventory.entity.TransactionType;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.inventory.repository.StockTransactionRepository;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class PredictionFeedbackService {

    private final AwayPredictionRepository predictionRepository;
    private final PredictionFeedbackRepository feedbackRepository;
    private final InventoryItemRepository inventoryItemRepository;
    private final StockTransactionRepository stockTransactionRepository;
    private final UserRepository userRepository;

    @Transactional
    public AwayPrediction acceptPrediction(UUID predictionId, UUID userId) {
        AwayPrediction prediction = predictionRepository.findById(predictionId)
                .orElseThrow(() -> new ResourceNotFoundException("Prediction not found: " + predictionId));

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

        InventoryItem item = prediction.getInventoryItem();
        BigDecimal previousQty = item.getQuantity() != null ? item.getQuantity() : BigDecimal.ZERO;
        BigDecimal newQty = prediction.getEstimatedQuantity();

        // 1. Update inventory item
        item.setQuantity(newQty);
        item.setQuantitySource(com.homestock.modules.consumption.entity.QuantitySource.ESTIMATED);
        item.setLastVerifiedAt(Instant.now());
        inventoryItemRepository.save(item);

        // 2. Record stock transaction
        BigDecimal qtyChange = newQty.subtract(previousQty);
        StockTransaction transaction = StockTransaction.builder()
                .home(prediction.getSummary().getHome())
                .item(item)
                .user(user)
                .transactionType(TransactionType.ADJUSTMENT)
                .quantityChange(qtyChange)
                .previousQuantity(previousQty)
                .newQuantity(newQty)
                .unit(prediction.getUnit())
                .reason("Confirmed from While You Were Away estimation")
                .build();
        stockTransactionRepository.save(transaction);

        // 3. Record feedback
        PredictionFeedback feedback = PredictionFeedback.builder()
                .prediction(prediction)
                .inventoryItem(item)
                .home(prediction.getSummary().getHome())
                .user(user)
                .feedbackType(FeedbackSignalType.PREDICTION_ACCEPTED)
                .predictedQuantity(prediction.getEstimatedQuantity())
                .actualQuantity(newQty)
                .errorDelta(BigDecimal.ZERO)
                .learningAdjustmentFactor(BigDecimal.ONE)
                .build();
        feedbackRepository.save(feedback);

        // 4. Update prediction status
        prediction.setStatus(PredictionStatus.ACCEPTED);
        predictionRepository.save(prediction);

        log.info("[PredictionFeedback] Accepted prediction {} for item '{}' by user {}. Quantity set to {}",
                predictionId, item.getName(), userId, newQty);

        return prediction;
    }

    @Transactional
    public AwayPrediction correctPrediction(UUID predictionId, BigDecimal actualQuantity, UUID userId) {
        AwayPrediction prediction = predictionRepository.findById(predictionId)
                .orElseThrow(() -> new ResourceNotFoundException("Prediction not found: " + predictionId));

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

        InventoryItem item = prediction.getInventoryItem();
        BigDecimal previousQty = item.getQuantity() != null ? item.getQuantity() : BigDecimal.ZERO;

        // 1. Calculate learning adjustment factor
        // If stockBefore = 2.0L, predicted remaining = 0.25L -> predicted consumed = 1.75L
        // User entered actual = 0.5L -> actual consumed = 1.5L
        // adjustmentFactor = actualConsumed / predictedConsumed = 1.5 / 1.75 = 0.857
        BigDecimal stockBefore = prediction.getStockBeforeAway() != null ? prediction.getStockBeforeAway() : previousQty;
        BigDecimal predictedConsumed = prediction.getEstimatedConsumed() != null && prediction.getEstimatedConsumed().compareTo(BigDecimal.ZERO) > 0
                ? prediction.getEstimatedConsumed()
                : BigDecimal.ONE;

        BigDecimal actualConsumed = stockBefore.subtract(actualQuantity);
        if (actualConsumed.compareTo(BigDecimal.ZERO) < 0) {
            actualConsumed = BigDecimal.ZERO;
        }

        BigDecimal adjustmentRatio = actualConsumed.divide(predictedConsumed, 4, RoundingMode.HALF_UP);
        // Clamp adjustment ratio to [0.20, 3.00] to prevent extreme volatility from a single observation
        if (adjustmentRatio.compareTo(new BigDecimal("0.20")) < 0) {
            adjustmentRatio = new BigDecimal("0.20");
        } else if (adjustmentRatio.compareTo(new BigDecimal("3.00")) > 0) {
            adjustmentRatio = new BigDecimal("3.00");
        }

        BigDecimal errorDelta = prediction.getEstimatedQuantity().subtract(actualQuantity).abs();

        // 2. Update inventory item
        item.setQuantity(actualQuantity);
        item.setQuantitySource(com.homestock.modules.consumption.entity.QuantitySource.VERIFIED);
        item.setLastVerifiedAt(Instant.now());
        inventoryItemRepository.save(item);

        // 3. Record stock transaction
        BigDecimal qtyChange = actualQuantity.subtract(previousQty);
        StockTransaction transaction = StockTransaction.builder()
                .home(prediction.getSummary().getHome())
                .item(item)
                .user(user)
                .transactionType(TransactionType.ADJUSTMENT)
                .quantityChange(qtyChange)
                .previousQuantity(previousQty)
                .newQuantity(actualQuantity)
                .unit(prediction.getUnit())
                .reason("User corrected stock from While You Were Away estimation")
                .build();
        stockTransactionRepository.save(transaction);

        // 4. Record feedback signal
        PredictionFeedback feedback = PredictionFeedback.builder()
                .prediction(prediction)
                .inventoryItem(item)
                .home(prediction.getSummary().getHome())
                .user(user)
                .feedbackType(FeedbackSignalType.PREDICTION_CORRECTED)
                .predictedQuantity(prediction.getEstimatedQuantity())
                .actualQuantity(actualQuantity)
                .errorDelta(errorDelta)
                .learningAdjustmentFactor(adjustmentRatio)
                .build();
        feedbackRepository.save(feedback);

        // 5. Update prediction status
        prediction.setStatus(PredictionStatus.CORRECTED);
        predictionRepository.save(prediction);

        log.info("[PredictionFeedback] Corrected prediction {} for item '{}': predicted={}, actual={}, adjustmentFactor={}",
                predictionId, item.getName(), prediction.getEstimatedQuantity(), actualQuantity, adjustmentRatio);

        return prediction;
    }

    @Transactional
    public AwayPrediction dismissPrediction(UUID predictionId, UUID userId) {
        AwayPrediction prediction = predictionRepository.findById(predictionId)
                .orElseThrow(() -> new ResourceNotFoundException("Prediction not found: " + predictionId));

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

        prediction.setStatus(PredictionStatus.DISMISSED);
        predictionRepository.save(prediction);

        PredictionFeedback feedback = PredictionFeedback.builder()
                .prediction(prediction)
                .inventoryItem(prediction.getInventoryItem())
                .home(prediction.getSummary().getHome())
                .user(user)
                .feedbackType(FeedbackSignalType.PREDICTION_REJECTED)
                .predictedQuantity(prediction.getEstimatedQuantity())
                .actualQuantity(null)
                .errorDelta(null)
                .learningAdjustmentFactor(BigDecimal.ONE)
                .build();
        feedbackRepository.save(feedback);

        log.info("[PredictionFeedback] Dismissed prediction {} for item '{}' by user {}",
                predictionId, prediction.getItemName(), userId);

        return prediction;
    }
}
