package com.homestock.modules.consumption.service;

import com.homestock.modules.consumption.dto.PredictionDto;
import com.homestock.modules.consumption.dto.SmartRecommendationDto;
import com.homestock.modules.consumption.entity.ConfidenceLevel;
import com.homestock.modules.consumption.entity.ConsumptionProfile;
import com.homestock.modules.consumption.entity.PredictionStatus;
import com.homestock.modules.consumption.entity.RecommendationUrgency;
import com.homestock.modules.consumption.repository.ConsumptionProfileRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class SmartRecommendationService {

    private final InventoryItemRepository inventoryItemRepository;
    private final ConsumptionProfileRepository consumptionProfileRepository;
    private final PredictionService predictionService;

    @Transactional(readOnly = true)
    public Map<RecommendationUrgency, List<SmartRecommendationDto>> getWhatDoINeed(UUID homeId) {
        List<InventoryItem> items = inventoryItemRepository.findAllByHomeIdAndIsArchivedFalseOrderByNameAsc(homeId);
        List<ConsumptionProfile> profiles = consumptionProfileRepository.findAllByHomeId(homeId);

        Map<UUID, ConsumptionProfile> profileMap = new HashMap<>();
        for (ConsumptionProfile p : profiles) {
            if (p.getInventoryItem() != null) {
                profileMap.put(p.getInventoryItem().getId(), p);
            }
        }

        List<SmartRecommendationDto> urgent = new ArrayList<>();
        List<SmartRecommendationDto> soon = new ArrayList<>();
        List<SmartRecommendationDto> optional = new ArrayList<>();

        for (InventoryItem item : items) {
            ConsumptionProfile profile = profileMap.get(item.getId());
            PredictionDto prediction = predictionService.predictItemStock(item, profile);

            BigDecimal restockQty = item.getMaximumQuantity() != null && item.getMaximumQuantity().compareTo(BigDecimal.ZERO) > 0
                    ? item.getMaximumQuantity().subtract(prediction.getCurrentQuantity()).max(BigDecimal.ONE)
                    : (profile != null && profile.getLastPurchaseQuantity() != null && profile.getLastPurchaseQuantity().compareTo(BigDecimal.ZERO) > 0
                        ? profile.getLastPurchaseQuantity()
                        : item.getMinimumQuantity().multiply(BigDecimal.valueOf(2)));

            if (prediction.getPredictionStatus() == PredictionStatus.OUT_OF_STOCK) {
                urgent.add(SmartRecommendationDto.builder()
                        .itemId(item.getId())
                        .name(item.getName())
                        .categoryName(prediction.getCategoryName())
                        .currentQuantity(prediction.getCurrentQuantity())
                        .formattedCurrentQuantity(prediction.getFormattedQuantity())
                        .recommendedQuantity(restockQty)
                        .unit(item.getUnit())
                        .urgency(RecommendationUrgency.URGENT)
                        .rationale(item.getName() + " is completely out of stock.")
                        .confidence(prediction.getConfidence())
                        .build());
            } else if (prediction.getPredictionStatus() == PredictionStatus.LIKELY_TO_RUN_OUT) {
                String rationale = (profile != null && profile.getAveragePurchaseInterval().compareTo(BigDecimal.ZERO) > 0)
                        ? "Likely to run out today based on your " + profile.getAveragePurchaseInterval().setScale(0, RoundingMode.HALF_UP) + "-day consumption cycle."
                        : "Stock is critically low and likely to run out today.";

                urgent.add(SmartRecommendationDto.builder()
                        .itemId(item.getId())
                        .name(item.getName())
                        .categoryName(prediction.getCategoryName())
                        .currentQuantity(prediction.getCurrentQuantity())
                        .formattedCurrentQuantity(prediction.getFormattedQuantity())
                        .recommendedQuantity(restockQty)
                        .unit(item.getUnit())
                        .urgency(RecommendationUrgency.URGENT)
                        .rationale(rationale)
                        .confidence(prediction.getConfidence())
                        .build());
            } else if (prediction.getPredictionStatus() == PredictionStatus.LOW) {
                String rationale;
                if (profile != null && profile.getSampleCount() >= 2) {
                    rationale = "Suggested because your home usually finishes " +
                            (profile.getLastPurchaseQuantity() != null ? profile.getLastPurchaseQuantity().stripTrailingZeros().toPlainString() + " " + item.getUnit() : "this stock") +
                            " in " + profile.getAveragePurchaseInterval().setScale(0, RoundingMode.HALF_UP) + " days.";
                } else {
                    rationale = "Running low below minimum reserve (" + item.getMinimumQuantity().stripTrailingZeros().toPlainString() + " " + item.getUnit() + ").";
                }

                soon.add(SmartRecommendationDto.builder()
                        .itemId(item.getId())
                        .name(item.getName())
                        .categoryName(prediction.getCategoryName())
                        .currentQuantity(prediction.getCurrentQuantity())
                        .formattedCurrentQuantity(prediction.getFormattedQuantity())
                        .recommendedQuantity(restockQty)
                        .unit(item.getUnit())
                        .urgency(RecommendationUrgency.SOON)
                        .rationale(rationale)
                        .confidence(prediction.getConfidence())
                        .build());
            } else if (prediction.getPredictionStatus() == PredictionStatus.WATCH) {
                optional.add(SmartRecommendationDto.builder()
                        .itemId(item.getId())
                        .name(item.getName())
                        .categoryName(prediction.getCategoryName())
                        .currentQuantity(prediction.getCurrentQuantity())
                        .formattedCurrentQuantity(prediction.getFormattedQuantity())
                        .recommendedQuantity(restockQty)
                        .unit(item.getUnit())
                        .urgency(RecommendationUrgency.OPTIONAL)
                        .rationale("Approaching usual restock window within this week.")
                        .confidence(prediction.getConfidence())
                        .build());
            }
        }

        Map<RecommendationUrgency, List<SmartRecommendationDto>> result = new EnumMap<>(RecommendationUrgency.class);
        result.put(RecommendationUrgency.URGENT, urgent);
        result.put(RecommendationUrgency.SOON, soon);
        result.put(RecommendationUrgency.OPTIONAL, optional);
        return result;
    }
}
