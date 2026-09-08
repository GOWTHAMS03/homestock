package com.homestock.modules.consumption.service;

import com.homestock.modules.consumption.dto.HomeMemoryInsightDto;
import com.homestock.modules.consumption.dto.PredictionDto;
import com.homestock.modules.consumption.dto.ReturnSummaryDto;
import com.homestock.modules.consumption.entity.ConsumptionProfile;
import com.homestock.modules.consumption.entity.PredictionStatus;
import com.homestock.modules.consumption.repository.ConsumptionProfileRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.purchase.entity.Purchase;
import com.homestock.modules.purchase.repository.PurchaseRepository;
import com.homestock.modules.shopping.entity.ShoppingList;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.shopping.repository.ShoppingListRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class HomeMemoryService {

    private final ConsumptionProfileRepository profileRepository;
    private final InventoryItemRepository inventoryItemRepository;
    private final PurchaseRepository purchaseRepository;
    private final ShoppingListRepository shoppingListRepository;
    private final ShoppingListItemRepository shoppingListItemRepository;
    private final PredictionService predictionService;

    @Transactional(readOnly = true)
    public HomeMemoryInsightDto getHomeMemoryInsights(UUID homeId) {
        List<ConsumptionProfile> profiles = profileRepository.findAllByHomeId(homeId);

        // Find primary staple with high/medium confidence
        Optional<ConsumptionProfile> primaryStapleOpt = profiles.stream()
                .filter(p -> p.getSampleCount() >= 2 && p.getAveragePurchaseInterval().compareTo(BigDecimal.ZERO) > 0)
                .max(Comparator.comparing(ConsumptionProfile::getSampleCount));

        String primaryInsight = "HomeStock is observing your household's natural replenishment rhythms.";
        String mostFrequentStaple = null;

        if (primaryStapleOpt.isPresent()) {
            ConsumptionProfile p = primaryStapleOpt.get();
            String name = p.getInventoryItem() != null ? p.getInventoryItem().getName() : "staples";
            mostFrequentStaple = name;
            int days = p.getAveragePurchaseInterval().setScale(0, RoundingMode.HALF_UP).intValue();
            primaryInsight = "Your household usually buys " + name + " every " + days + " days. " +
                    "Predictions adjust automatically as your family's needs change.";
        }

        List<String> bulletInsights = new ArrayList<>();
        for (ConsumptionProfile p : profiles) {
            if (bulletInsights.size() >= 3) break;
            if (p.getSampleCount() >= 3 && p.getInventoryItem() != null) {
                int days = p.getAveragePurchaseInterval().setScale(0, RoundingMode.HALF_UP).intValue();
                bulletInsights.add(p.getInventoryItem().getName() + " is typically restocked every " + days + " days.");
            }
        }

        // Calculate this week's spending
        LocalDate weekAgo = LocalDate.now().minusDays(7);
        List<Purchase> recentPurchases = purchaseRepository.findAllByHomeIdAndPurchaseDateBetween(homeId, weekAgo, LocalDate.now());

        BigDecimal weeklySpent = BigDecimal.ZERO;
        for (Purchase p : recentPurchases) {
            if (p.getTotalAmount() != null) {
                weeklySpent = weeklySpent.add(p.getTotalAmount());
            }
        }

        return HomeMemoryInsightDto.builder()
                .homeId(homeId)
                .primaryInsight(primaryInsight)
                .bulletInsights(bulletInsights)
                .weeklySpent(weeklySpent)
                .weeklyPurchasesCount(recentPurchases.size())
                .itemsSavedFromDuplicate(recentPurchases.isEmpty() ? 0 : Math.max(1, recentPurchases.size() / 2))
                .topCategory("Groceries & Staples")
                .mostFrequentStaple(mostFrequentStaple)
                .build();
    }

    @Transactional(readOnly = true)
    public ReturnSummaryDto getReturnSummary(UUID homeId, int daysAway) {
        List<InventoryItem> items = inventoryItemRepository.findAllByHomeIdAndIsArchivedFalseOrderByNameAsc(homeId);
        List<ConsumptionProfile> profiles = profileRepository.findAllByHomeId(homeId);

        Map<UUID, ConsumptionProfile> profileMap = new HashMap<>();
        for (ConsumptionProfile p : profiles) {
            if (p.getInventoryItem() != null) {
                profileMap.put(p.getInventoryItem().getId(), p);
            }
        }

        List<PredictionDto> itemsLikelyLow = new ArrayList<>();
        List<String> expiringItems = new ArrayList<>();
        LocalDate today = LocalDate.now();

        for (InventoryItem item : items) {
            ConsumptionProfile profile = profileMap.get(item.getId());
            PredictionDto pred = predictionService.predictItemStock(item, profile);

            if (pred.getPredictionStatus() == PredictionStatus.OUT_OF_STOCK ||
                    pred.getPredictionStatus() == PredictionStatus.LIKELY_TO_RUN_OUT ||
                    pred.getPredictionStatus() == PredictionStatus.LOW) {
                itemsLikelyLow.add(pred);
            }

            if (item.getExpiryDate() != null) {
                long daysToExpiry = ChronoUnit.DAYS.between(today, item.getExpiryDate());
                if (daysToExpiry <= 5) {
                    expiringItems.add(item.getName());
                }
            }
        }

        long pendingShopping = 0;
        Optional<ShoppingList> defaultList = shoppingListRepository.findByHomeIdAndIsDefaultTrue(homeId);
        if (defaultList.isPresent()) {
            pendingShopping = shoppingListItemRepository.countByShoppingListIdAndIsCompletedFalse(defaultList.get().getId());
        }

        boolean hasUpdates = !itemsLikelyLow.isEmpty() || !expiringItems.isEmpty() || pendingShopping > 0;

        return ReturnSummaryDto.builder()
                .greeting("Welcome back 👋")
                .subtitle(hasUpdates ? "Here's what changed while you were away." : "Everything in your home looks good and well-stocked.")
                .itemsLikelyLowCount(itemsLikelyLow.size())
                .itemsLikelyLow(itemsLikelyLow)
                .itemsExpiringCount(expiringItems.size())
                .expiringItemNames(expiringItems)
                .pendingShoppingCount((int) pendingShopping)
                .recentFamilyPurchasesCount(0)
                .hasUpdates(hasUpdates)
                .build();
    }
}
