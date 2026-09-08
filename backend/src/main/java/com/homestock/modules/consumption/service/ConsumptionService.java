package com.homestock.modules.consumption.service;

import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.consumption.dto.*;
import com.homestock.modules.consumption.entity.*;
import com.homestock.modules.consumption.repository.ConsumptionCycleRepository;
import com.homestock.modules.consumption.repository.ConsumptionProfileRepository;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.purchase.entity.PurchaseItem;
import com.homestock.modules.purchase.repository.PurchaseItemRepository;
import com.homestock.modules.shopping.entity.ShoppingList;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.shopping.repository.ShoppingListRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class ConsumptionService {

    private final ConsumptionProfileRepository profileRepository;
    private final ConsumptionCycleRepository cycleRepository;
    private final InventoryItemRepository inventoryItemRepository;
    private final PurchaseItemRepository purchaseItemRepository;
    private final HomeRepository homeRepository;
    private final ShoppingListRepository shoppingListRepository;
    private final ShoppingListItemRepository shoppingListItemRepository;

    private final ConsumptionCalculationService calculationService;
    private final StockEstimationService stockEstimationService;
    private final PredictionService predictionService;
    private final SmartRecommendationService smartRecommendationService;
    private final HomeMemoryService homeMemoryService;
    private final NotificationDecisionService notificationDecisionService;

    /**
     * Event Trigger: called whenever a purchase is recorded for an inventory item.
     * Rebuilds consumption cycles and updates the consumption profile.
     */
    @Transactional
    public void onPurchaseRecorded(Home home, InventoryItem item, BigDecimal quantity, LocalDate purchaseDate) {
        if (item == null || home == null) return;

        log.info("Triggering consumption learning for item '{}' in home '{}'", item.getName(), home.getName());

        // 1. Fetch all purchase history for this item
        List<PurchaseItem> purchaseHistory = purchaseItemRepository.findAllByInventoryItemId(item.getId());

        // 2. Reconstruct consumption cycles
        List<ConsumptionCycle> cycles = calculationService.buildCyclesFromPurchases(home, item, purchaseHistory);

        // Delete existing cycles and persist recalculated cycles
        List<ConsumptionCycle> existingCycles = cycleRepository.findAllByHomeIdAndInventoryItemIdOrderByCurrentPurchaseDateDesc(home.getId(), item.getId());
        cycleRepository.deleteAll(existingCycles);
        if (!cycles.isEmpty()) {
            cycleRepository.saveAll(cycles);
        }

        // 3. Compute or update profile
        Optional<ConsumptionProfile> existingProfileOpt = profileRepository.findByHomeIdAndInventoryItemId(home.getId(), item.getId());
        ConsumptionProfile profile = calculationService.calculateProfile(home, item, cycles, existingProfileOpt.orElse(null));

        // Update estimated days remaining
        Integer daysRemaining = stockEstimationService.calculateDaysRemaining(item.getQuantity(), profile);
        profile.setEstimatedDaysRemaining(daysRemaining);

        profileRepository.save(profile);

        // 4. Update item metadata: source = VERIFIED, lastVerifiedAt = now
        item.setQuantitySource(QuantitySource.VERIFIED);
        item.setLastVerifiedAt(Instant.now());
        item.setConfidence(profile.getConfidence());
        inventoryItemRepository.save(item);

        log.info("Updated consumption profile for item '{}': weightedDaily={}, confidence={}",
                item.getName(), profile.getWeightedDailyConsumption(), profile.getConfidence());
    }

    /**
     * Recalculate consumption profile for a specific item on demand (e.g. after sync).
     */
    @Transactional
    public void recalculateForItem(Home home, UUID itemId) {
        inventoryItemRepository.findByIdAndHomeId(itemId, home.getId()).ifPresent(item -> {
            List<PurchaseItem> purchaseHistory = purchaseItemRepository.findAllByInventoryItemId(item.getId());
            List<ConsumptionCycle> cycles = calculationService.buildCyclesFromPurchases(home, item, purchaseHistory);

            List<ConsumptionCycle> existingCycles = cycleRepository.findAllByHomeIdAndInventoryItemIdOrderByCurrentPurchaseDateDesc(home.getId(), item.getId());
            cycleRepository.deleteAll(existingCycles);
            if (!cycles.isEmpty()) {
                cycleRepository.saveAll(cycles);
            }

            Optional<ConsumptionProfile> existingProfileOpt = profileRepository.findByHomeIdAndInventoryItemId(home.getId(), item.getId());
            ConsumptionProfile profile = calculationService.calculateProfile(home, item, cycles, existingProfileOpt.orElse(null));
            profileRepository.save(profile);
        });
    }

    /**
     * Fast qualitative status confirmation in 2 taps.
     */
    @Transactional
    public PredictionDto confirmStatus(UUID itemId, ConfirmStatusRequest request) {
        InventoryItem item = inventoryItemRepository.findById(itemId)
                .orElseThrow(() -> new ResourceNotFoundException("Inventory item not found"));

        Home home = item.getHome();

        if ("ADD_TO_SHOPPING".equalsIgnoreCase(request.getAction())) {
            // Add replenishment to default shopping list
            shoppingListRepository.findByHomeIdAndIsDefaultTrue(home.getId()).ifPresent(list -> {
                boolean alreadyInList = shoppingListItemRepository.findActiveItemByInventoryItemId(list.getId(), item.getId()).isPresent();
                if (!alreadyInList) {
                    BigDecimal restockQty = item.getMinimumQuantity().multiply(BigDecimal.valueOf(2));
                    ShoppingListItem sli = ShoppingListItem.builder()
                            .shoppingList(list)
                            .inventoryItem(item)
                            .itemName(item.getName())
                            .quantity(restockQty)
                            .unit(item.getUnit())
                            .isCompleted(false)
                            .isAutoGenerated(false)
                            .build();
                    shoppingListItemRepository.save(sli);
                    log.info("Added {} to shopping list via Smart Confirmation", item.getName());
                }
            });
        } else if ("STILL_HAVE_ENOUGH".equalsIgnoreCase(request.getAction())) {
            // User confirms they still have stock: reset consumption reference timestamp to now!
            item.setQuantitySource(QuantitySource.VERIFIED);
            item.setLastVerifiedAt(Instant.now());
            item.setQuantityStatus(QuantityStatus.ABOUT_HALF);
            inventoryItemRepository.save(item);
        } else if (request.getStatus() != null) {
            // Qualitative ratio selection
            QuantityStatus status = request.getStatus();
            item.setQuantityStatus(status);
            item.setQuantitySource(QuantitySource.VERIFIED);
            item.setLastVerifiedAt(Instant.now());

            BigDecimal referenceCapacity = item.getMaximumQuantity() != null && item.getMaximumQuantity().compareTo(BigDecimal.ZERO) > 0
                    ? item.getMaximumQuantity()
                    : item.getMinimumQuantity().multiply(BigDecimal.valueOf(2));

            BigDecimal updatedQty = referenceCapacity.multiply(status.getApproximateRatio()).setScale(2, RoundingMode.HALF_UP);
            item.setQuantity(updatedQty);
            inventoryItemRepository.save(item);
        }

        ConsumptionProfile profile = profileRepository.findByHomeIdAndInventoryItemId(home.getId(), item.getId()).orElse(null);
        return predictionService.predictItemStock(item, profile);
    }

    /**
     * Exact quantity confirmation.
     */
    @Transactional
    public PredictionDto confirmQuantity(UUID itemId, ConfirmQuantityRequest request) {
        InventoryItem item = inventoryItemRepository.findById(itemId)
                .orElseThrow(() -> new ResourceNotFoundException("Inventory item not found"));

        item.setQuantity(request.getQuantity());
        item.setQuantitySource(QuantitySource.VERIFIED);
        item.setLastVerifiedAt(Instant.now());
        item.setQuantityStatus(QuantityStatus.fromRatio(
                item.getMinimumQuantity().compareTo(BigDecimal.ZERO) > 0 ?
                        request.getQuantity().divide(item.getMinimumQuantity().multiply(BigDecimal.valueOf(2)), 2, RoundingMode.HALF_UP) : BigDecimal.ONE
        ));

        if (request.getUnit() != null && !request.getUnit().isBlank()) {
            item.setUnit(request.getUnit().trim());
        }

        InventoryItem savedItem = inventoryItemRepository.save(item);
        ConsumptionProfile profile = profileRepository.findByHomeIdAndInventoryItemId(item.getHome().getId(), item.getId()).orElse(null);
        return predictionService.predictItemStock(savedItem, profile);
    }

    @Transactional(readOnly = true)
    public ConsumptionProfileDto getConsumptionProfile(UUID homeId, UUID itemId) {
        InventoryItem item = inventoryItemRepository.findByIdAndHomeId(itemId, homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Inventory item not found"));

        ConsumptionProfile profile = profileRepository.findByHomeIdAndInventoryItemId(homeId, itemId).orElse(null);
        if (profile == null) {
            return null;
        }

        String explanation = calculationService.getConfidenceExplanation(
                profile.getConfidence(), profile.getSampleCount(), profile.getAveragePurchaseInterval(), item.getName()
        );
        String typicalRange = calculationService.formatTypicalRangeText(
                profile.getMinDailyConsumption(), profile.getMaxDailyConsumption(), profile.getAveragePurchaseInterval(),
                item.getUnit(), profile.getLastPurchaseQuantity()
        );

        return ConsumptionProfileDto.fromEntity(profile, explanation, typicalRange);
    }

    @Transactional(readOnly = true)
    public List<ConsumptionProfileDto> getAllConsumptionProfiles(UUID homeId) {
        List<ConsumptionProfile> profiles = profileRepository.findAllByHomeId(homeId);
        List<ConsumptionProfileDto> dtos = new ArrayList<>();

        for (ConsumptionProfile p : profiles) {
            String itemName = p.getInventoryItem() != null ? p.getInventoryItem().getName() : "Item";
            String unit = p.getInventoryItem() != null ? p.getInventoryItem().getUnit() : "pcs";
            String explanation = calculationService.getConfidenceExplanation(
                    p.getConfidence(), p.getSampleCount(), p.getAveragePurchaseInterval(), itemName
            );
            String typicalRange = calculationService.formatTypicalRangeText(
                    p.getMinDailyConsumption(), p.getMaxDailyConsumption(), p.getAveragePurchaseInterval(),
                    unit, p.getLastPurchaseQuantity()
            );
            dtos.add(ConsumptionProfileDto.fromEntity(p, explanation, typicalRange));
        }
        return dtos;
    }

    @Transactional(readOnly = true)
    public List<PredictionDto> getAllPredictions(UUID homeId) {
        List<InventoryItem> items = inventoryItemRepository.findAllByHomeIdAndIsArchivedFalseOrderByNameAsc(homeId);
        List<ConsumptionProfile> profiles = profileRepository.findAllByHomeId(homeId);

        Map<UUID, ConsumptionProfile> profileMap = new HashMap<>();
        for (ConsumptionProfile p : profiles) {
            if (p.getInventoryItem() != null) {
                profileMap.put(p.getInventoryItem().getId(), p);
            }
        }

        List<PredictionDto> predictions = new ArrayList<>();
        for (InventoryItem item : items) {
            ConsumptionProfile p = profileMap.get(item.getId());
            predictions.add(predictionService.predictItemStock(item, p));
        }
        return predictions;
    }

    @Transactional(readOnly = true)
    public Map<RecommendationUrgency, List<SmartRecommendationDto>> getSmartRecommendations(UUID homeId) {
        return smartRecommendationService.getWhatDoINeed(homeId);
    }

    @Transactional(readOnly = true)
    public HomeMemoryInsightDto getHomeMemoryInsights(UUID homeId) {
        return homeMemoryService.getHomeMemoryInsights(homeId);
    }

    @Transactional(readOnly = true)
    public ReturnSummaryDto getReturnSummary(UUID homeId, int daysAway) {
        return homeMemoryService.getReturnSummary(homeId, daysAway);
    }
}
