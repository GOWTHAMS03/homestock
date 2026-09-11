package com.homestock.modules.away.service;

import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.away.dto.AwayPredictionDto;
import com.homestock.modules.away.dto.AwaySummaryResponseDto;
import com.homestock.modules.away.entity.*;
import com.homestock.modules.away.repository.AwayPeriodSummaryRepository;
import com.homestock.modules.away.repository.AwayPredictionRepository;
import com.homestock.modules.away.repository.UserActivityLogRepository;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.shopping.entity.ShoppingList;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.shopping.repository.ShoppingListRepository;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class AwaySummaryService {

    private final AwayPeriodDetector awayPeriodDetector;
    private final ConsumptionHistoryService consumptionHistoryService;
    private final InventoryPredictionService inventoryPredictionService;
    private final ExpiryPredictionService expiryPredictionService;
    private final RestockPredictionService restockPredictionService;
    private final AwayPeriodSummaryRepository summaryRepository;
    private final AwayPredictionRepository predictionRepository;
    private final UserActivityLogRepository activityLogRepository;
    private final InventoryItemRepository inventoryItemRepository;
    private final ShoppingListRepository shoppingListRepository;
    private final ShoppingListItemRepository shoppingListItemRepository;
    private final HomeRepository homeRepository;
    private final UserRepository userRepository;

    @Value("${app.away-summary.max-summary-items:5}")
    private int maxSummaryItems = 5;

    @Transactional
    public AwaySummaryResponseDto getAwaySummary(UUID userId, UUID homeId) {
        AwayPeriodDetector.DetectionResult detection = awayPeriodDetector.detectInactivity(userId, homeId);

        LocalDate toDate = LocalDate.now();
        LocalDate fromDate = detection.getLastMeaningfulActivityDate().atZone(ZoneId.systemDefault()).toLocalDate();

        if (!detection.isAway()) {
            return AwaySummaryResponseDto.builder()
                    .isAway(false)
                    .awayDays(detection.getAwayDays())
                    .from(fromDate)
                    .to(toDate)
                    .greeting("Welcome back")
                    .subtitle("Your household pantry is up to date.")
                    .summary(AwaySummaryResponseDto.AwaySummaryCounts.builder()
                            .importantChanges(0)
                            .predictedLowStock(0)
                            .predictedFinished(0)
                            .expiryRisks(0)
                            .build())
                    .predictions(List.of())
                    .topPredictions(List.of())
                    .knownFamilyEvents(List.of())
                    .hasUnreviewedUpdates(false)
                    .build();
        }

        // Check if recent unreviewed summary already exists (created within last 6 hours)
        Instant sixHoursAgo = Instant.now().minus(6, ChronoUnit.HOURS);
        Optional<AwayPeriodSummary> cachedSummaryOpt = summaryRepository.findRecentSummary(homeId, userId, sixHoursAgo);
        if (cachedSummaryOpt.isPresent()) {
            AwayPeriodSummary cached = cachedSummaryOpt.get();
            if (!cached.getIsReviewed()) {
                return mapToResponseDto(cached, detection.getFamilyActivityDuringAway());
            }
        }

        // Generate fresh Away Period Summary
        Home home = homeRepository.findById(homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Home not found: " + homeId));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

        List<InventoryItem> items = inventoryItemRepository.findAllByHomeIdAndIsArchivedFalseOrderByNameAsc(homeId);

        List<AwayPrediction> candidatePredictions = new ArrayList<>();
        int countRanOut = 0;
        int countLowStock = 0;
        int countExpiry = 0;

        for (InventoryItem item : items) {
            ConsumptionHistoryService.ItemBaselineHistory history = consumptionHistoryService.getItemHistoryBeforeAway(
                    item, homeId, detection.getLastMeaningfulActivityDate(), detection.getReturnDate()
            );

            // 1. Predict Inventory & Runout
            InventoryPredictionService.InventoryPredictionResult invPred = inventoryPredictionService.predictInventoryChange(
                    item, history, fromDate, toDate
            );

            // 2. Predict Expiry
            Optional<ExpiryPredictionService.ExpiryRiskResult> expiryPred = expiryPredictionService.evaluateExpiryRisk(
                    item, fromDate, toDate
            );

            // 3. Predict Restock Cycle
            Optional<RestockPredictionService.RestockRequirementResult> restockPred = restockPredictionService.evaluateRestockCycle(
                    item, history.getAveragePurchaseInterval(), detection.getAwayDays(), invPred.getEstimatedQuantity()
            );

            // Synthesize item prediction
            AwayPredictionType finalType = invPred.getPredictionType();
            String reason = invPred.getReason();
            double confidence = invPred.getConfidence();

            if (expiryPred.isPresent() && expiryPred.get().getPredictionType() == AwayPredictionType.MAY_HAVE_EXPIRED) {
                finalType = AwayPredictionType.MAY_HAVE_EXPIRED;
                reason = expiryPred.get().getReason();
                confidence = Math.max(confidence, expiryPred.get().getConfidence());
                countExpiry++;
            } else if (invPred.getPredictionType() == AwayPredictionType.LIKELY_RAN_OUT) {
                countRanOut++;
            } else if (invPred.getPredictionType() == AwayPredictionType.LIKELY_LOW) {
                countLowStock++;
            } else if (expiryPred.isPresent() && expiryPred.get().getPredictionType() == AwayPredictionType.EXPIRING_SOON) {
                finalType = AwayPredictionType.EXPIRING_SOON;
                reason = expiryPred.get().getReason();
                confidence = Math.max(confidence, expiryPred.get().getConfidence());
                countExpiry++;
            } else if (restockPred.isPresent() && restockPred.get().isNeedsRestock()) {
                finalType = AwayPredictionType.RESTOCK_RECOMMENDED;
                reason = restockPred.get().getReason();
                confidence = Math.max(confidence, restockPred.get().getConfidence());
            }

            // Only add non-trivial predictions
            if (finalType != AwayPredictionType.NORMAL || invPred.isColdStart()) {
                AwayPrediction pred = AwayPrediction.builder()
                        .inventoryItem(item)
                        .itemName(item.getName())
                        .predictionType(finalType)
                        .eventClassification(PredictionEventClassification.PREDICTED_EVENT)
                        .stockBeforeAway(invPred.getStockBeforeAway())
                        .estimatedQuantity(invPred.getEstimatedQuantity())
                        .estimatedConsumed(invPred.getEstimatedConsumed())
                        .unit(item.getUnit() != null ? item.getUnit() : "units")
                        .confidence(BigDecimal.valueOf(confidence))
                        .reason(reason)
                        .status(PredictionStatus.PENDING)
                        .isTopPriority(false)
                        .build();

                candidatePredictions.add(pred);
            }
        }

        // Rank candidate predictions by priority tier then confidence DESC
        candidatePredictions.sort((a, b) -> {
            int pA = getPriorityRank(a.getPredictionType());
            int pB = getPriorityRank(b.getPredictionType());
            if (pA != pB) {
                return Integer.compare(pA, pB);
            }
            return b.getConfidence().compareTo(a.getConfidence());
        });

        // Mark top 3-5 as top priority
        for (int i = 0; i < candidatePredictions.size(); i++) {
            if (i < maxSummaryItems && candidatePredictions.get(i).getPredictionType() != AwayPredictionType.NORMAL) {
                candidatePredictions.get(i).setIsTopPriority(true);
            }
        }

        int importantChanges = countRanOut + countLowStock + countExpiry;

        // Persist summary
        AwayPeriodSummary summary = AwayPeriodSummary.builder()
                .home(home)
                .user(user)
                .awayDays(detection.getAwayDays())
                .fromDate(detection.getLastMeaningfulActivityDate())
                .toDate(detection.getReturnDate())
                .importantChanges(importantChanges)
                .predictedLowStock(countLowStock)
                .predictedFinished(countRanOut)
                .expiryRisks(countExpiry)
                .isReviewed(false)
                .build();

        summaryRepository.save(summary);

        for (AwayPrediction p : candidatePredictions) {
            p.setSummary(summary);
            predictionRepository.save(p);
        }

        summary.setPredictions(candidatePredictions);

        log.info("[AwaySummaryService] Generated away summary for user {} home {}: awayDays={}, importantChanges={}",
                userId, homeId, detection.getAwayDays(), importantChanges);

        return mapToResponseDto(summary, detection.getFamilyActivityDuringAway());
    }

    private int getPriorityRank(AwayPredictionType type) {
        if (type == null) return 99;
        return switch (type) {
            case LIKELY_RAN_OUT -> 1;
            case MAY_HAVE_EXPIRED -> 2;
            case LIKELY_LOW -> 3;
            case EXPIRING_SOON -> 4;
            case RESTOCK_RECOMMENDED -> 5;
            case NORMAL -> 6;
        };
    }

    private AwaySummaryResponseDto mapToResponseDto(AwayPeriodSummary summary, List<String> familyEvents) {
        LocalDate fromDate = summary.getFromDate().atZone(ZoneId.systemDefault()).toLocalDate();
        LocalDate toDate = summary.getToDate().atZone(ZoneId.systemDefault()).toLocalDate();

        List<AwayPredictionDto> allDtos = new ArrayList<>();
        List<AwayPredictionDto> topDtos = new ArrayList<>();

        List<AwayPrediction> preds = predictionRepository.findBySummaryIdOrderByConfidenceDesc(summary.getId());
        for (AwayPrediction p : preds) {
            AwayPredictionDto dto = mapPredictionToDto(p);
            allDtos.add(dto);
            if (Boolean.TRUE.equals(p.getIsTopPriority())) {
                topDtos.add(dto);
            }
        }

        String greeting = String.format("While you were away · %d days 👋", summary.getAwayDays());
        String subtitle = summary.getImportantChanges() > 0
                ? "Your home probably changed a little based on your usual usage."
                : "Everything in your home appears to be running smoothly.";

        return AwaySummaryResponseDto.builder()
                .summaryId(summary.getId())
                .isAway(true)
                .awayDays(summary.getAwayDays())
                .from(fromDate)
                .to(toDate)
                .greeting(greeting)
                .subtitle(subtitle)
                .summary(AwaySummaryResponseDto.AwaySummaryCounts.builder()
                        .importantChanges(summary.getImportantChanges())
                        .predictedLowStock(summary.getPredictedLowStock())
                        .predictedFinished(summary.getPredictedFinished())
                        .expiryRisks(summary.getExpiryRisks())
                        .build())
                .predictions(allDtos)
                .topPredictions(topDtos)
                .knownFamilyEvents(familyEvents != null ? familyEvents : List.of())
                .hasUnreviewedUpdates(!summary.getIsReviewed())
                .build();
    }

    private AwayPredictionDto mapPredictionToDto(AwayPrediction p) {
        String displayTitle = switch (p.getPredictionType()) {
            case LIKELY_RAN_OUT -> "Probably ran out";
            case LIKELY_LOW -> "Likely running low";
            case MAY_HAVE_EXPIRED -> "May have expired";
            case EXPIRING_SOON -> "Expiring soon";
            case RESTOCK_RECOMMENDED -> "Restock recommended";
            case NORMAL -> "Likely in stock";
        };

        String displaySubtitle = switch (p.getPredictionType()) {
            case LIKELY_RAN_OUT -> "Based on your usual usage while you were away";
            case LIKELY_LOW -> String.format("~%s %s estimated remaining",
                    p.getEstimatedQuantity().stripTrailingZeros().toPlainString(), p.getUnit());
            case MAY_HAVE_EXPIRED -> "Expiry date fell during your absence. Check before using.";
            case EXPIRING_SOON -> "Close to package expiry date. Check before using.";
            case RESTOCK_RECOMMENDED -> "Replenishment interval elapsed during your absence";
            case NORMAL -> String.format("~%s %s estimated remaining",
                    p.getEstimatedQuantity().stripTrailingZeros().toPlainString(), p.getUnit());
        };

        String actionLabel = switch (p.getPredictionType()) {
            case LIKELY_RAN_OUT, LIKELY_LOW -> "Add to Shopping List";
            case MAY_HAVE_EXPIRED, EXPIRING_SOON -> "Check & Update";
            default -> "Looks right";
        };

        long confPct = Math.round(p.getConfidence().doubleValue() * 100);

        return AwayPredictionDto.builder()
                .id(p.getId())
                .inventoryItemId(p.getInventoryItem() != null ? p.getInventoryItem().getId() : null)
                .itemName(p.getItemName())
                .type(p.getPredictionType())
                .eventClassification(p.getEventClassification())
                .stockBeforeAway(p.getStockBeforeAway())
                .estimatedQuantity(p.getEstimatedQuantity())
                .estimatedConsumed(p.getEstimatedConsumed())
                .unit(p.getUnit())
                .confidence(p.getConfidence().doubleValue())
                .confidenceLabel(confPct + "% confidence")
                .isPrediction(true)
                .reason(p.getReason())
                .displayTitle(displayTitle)
                .displaySubtitle(displaySubtitle)
                .actionLabel(actionLabel)
                .status(p.getStatus())
                .isTopPriority(p.getIsTopPriority())
                .build();
    }

    @Transactional
    public void recordHeartbeat(UUID userId, UUID homeId, UserActivityType type, String metadata) {
        User user = userRepository.findById(userId).orElse(null);
        Home home = homeRepository.findById(homeId).orElse(null);
        if (user == null || home == null) return;

        UserActivityLog logEntry = UserActivityLog.builder()
                .user(user)
                .home(home)
                .activityType(type != null ? type : UserActivityType.APP_OPEN)
                .metadata(metadata)
                .occurredAt(Instant.now())
                .build();
        activityLogRepository.save(logEntry);
    }

    @Transactional
    public int addPredictedItemsToShoppingList(UUID userId, UUID homeId, List<UUID> predictionIds) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));
        Home home = homeRepository.findById(homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Home not found: " + homeId));

        ShoppingList defaultList = shoppingListRepository.findByHomeIdAndIsDefaultTrue(homeId)
                .orElseGet(() -> {
                    ShoppingList newList = ShoppingList.builder()
                            .home(home)
                            .name("Household Shopping List")
                            .isDefault(true)
                            .build();
                    return shoppingListRepository.save(newList);
                });

        List<AwayPrediction> toAdd = new ArrayList<>();
        if (predictionIds != null && !predictionIds.isEmpty()) {
            toAdd = predictionRepository.findAllById(predictionIds);
        } else {
            // Default: add all unhandled ran out / low items in the latest unreviewed summary
            List<AwayPeriodSummary> summaries = summaryRepository.findUnreviewedSummaries(homeId, userId);
            if (!summaries.isEmpty()) {
                List<AwayPrediction> preds = predictionRepository.findAllBySummaryIdAndStatus(
                        summaries.getFirst().getId(), PredictionStatus.PENDING
                );
                for (AwayPrediction p : preds) {
                    if (p.getPredictionType() == AwayPredictionType.LIKELY_RAN_OUT ||
                            p.getPredictionType() == AwayPredictionType.LIKELY_LOW) {
                        toAdd.add(p);
                    }
                }
            }
        }

        int addedCount = 0;
        for (AwayPrediction pred : toAdd) {
            InventoryItem invItem = pred.getInventoryItem();
            if (invItem == null) continue;

            // Check if active item already exists on list
            Optional<ShoppingListItem> existing = shoppingListItemRepository.findActiveItemByHomeIdAndInventoryItemId(
                    homeId, invItem.getId()
            );
            if (existing.isPresent()) {
                continue;
            }

            BigDecimal qtyNeeded = invItem.getMinimumQuantity() != null && invItem.getMinimumQuantity().compareTo(BigDecimal.ZERO) > 0
                    ? invItem.getMinimumQuantity()
                    : BigDecimal.ONE;

            ShoppingListItem item = ShoppingListItem.builder()
                    .shoppingList(defaultList)
                    .inventoryItem(invItem)
                    .product(invItem.getProduct())
                    .barcode(invItem.getBarcode())
                    .itemName(invItem.getName())
                    .category(invItem.getCategory())
                    .quantity(qtyNeeded)
                    .unit(invItem.getUnit() != null ? invItem.getUnit() : "pcs")
                    .isCompleted(false)
                    .isAutoGenerated(true)
                    .addedBy(user)
                    .notes("Added from While You Were Away estimation")
                    .build();

            shoppingListItemRepository.save(item);
            addedCount++;
        }

        log.info("[AwaySummaryService] Added {} predicted items to shopping list for home {}", addedCount, homeId);
        return addedCount;
    }

    @Transactional
    public void dismissAll(UUID summaryId, UUID userId) {
        AwayPeriodSummary summary = summaryRepository.findById(summaryId)
                .orElseThrow(() -> new ResourceNotFoundException("Summary not found: " + summaryId));
        summary.setIsReviewed(true);
        summaryRepository.save(summary);
    }
}
