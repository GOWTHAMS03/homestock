package com.homestock.modules.smartshopping.service;

import com.homestock.modules.consumption.entity.ConsumptionProfile;
import com.homestock.modules.consumption.repository.ConsumptionProfileRepository;
import com.homestock.modules.consumption.service.StockEstimationService;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.smartshopping.dto.DuplicateWarningDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.*;

/**
 * Cross-references shopping list items with existing household inventory
 * and consumption runout forecasts to warn against unintentional duplicate purchases.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DuplicateProtectionService {

    private final InventoryItemRepository inventoryItemRepository;
    private final ConsumptionProfileRepository consumptionProfileRepository;
    private final StockEstimationService stockEstimationService;

    /**
     * Checks a list of shopping items against home inventory for duplicate purchase warnings.
     */
    public List<DuplicateWarningDto> checkDuplicates(UUID homeId, List<ShoppingListItem> shoppingItems) {
        if (shoppingItems == null || shoppingItems.isEmpty()) {
            return List.of();
        }

        List<InventoryItem> homeInventory = inventoryItemRepository.findAllByHomeIdAndIsArchivedFalseOrderByNameAsc(homeId);
        List<ConsumptionProfile> profiles = consumptionProfileRepository.findAllByHomeId(homeId);
        Map<UUID, ConsumptionProfile> profileByItemId = new HashMap<>();
        for (ConsumptionProfile p : profiles) {
            if (p.getInventoryItem() != null) {
                profileByItemId.put(p.getInventoryItem().getId(), p);
            }
        }

        List<DuplicateWarningDto> warnings = new ArrayList<>();

        for (ShoppingListItem shoppingItem : shoppingItems) {
            InventoryItem matchedItem = findMatchingInventoryItem(shoppingItem, homeInventory);
            if (matchedItem == null) continue;

            ConsumptionProfile profile = profileByItemId.get(matchedItem.getId());
            BigDecimal effectiveQty = stockEstimationService.estimateCurrentQuantity(matchedItem, profile);
            Integer daysRemaining = stockEstimationService.calculateDaysRemaining(effectiveQty, profile);

            boolean hasAmpleStock = false;
            String message = null;

            if (daysRemaining != null && daysRemaining >= 7) {
                hasAmpleStock = true;
                message = String.format("You already have about %s %s %s at home (enough for ~%d days).",
                        formatQuantity(effectiveQty), matchedItem.getUnit(), matchedItem.getName(), daysRemaining);
            } else if (effectiveQty.compareTo(matchedItem.getMinimumQuantity().multiply(BigDecimal.valueOf(1.5))) > 0
                    && effectiveQty.compareTo(BigDecimal.ZERO) > 0) {
                hasAmpleStock = true;
                message = String.format("You have %s %s %s at home, which is well above your minimum threshold.",
                        formatQuantity(effectiveQty), matchedItem.getUnit(), matchedItem.getName());
            }

            if (hasAmpleStock) {
                warnings.add(DuplicateWarningDto.builder()
                        .shoppingItemId(shoppingItem.getId())
                        .itemName(shoppingItem.getItemName())
                        .existingStockQuantity(effectiveQty)
                        .existingStockUnit(matchedItem.getUnit())
                        .estimatedDaysRemaining(daysRemaining != null ? daysRemaining.doubleValue() : null)
                        .message(message)
                        .build());
            }
        }

        return warnings;
    }

    private InventoryItem findMatchingInventoryItem(ShoppingListItem shoppingItem, List<InventoryItem> homeInventory) {
        if (shoppingItem.getInventoryItem() != null) {
            return shoppingItem.getInventoryItem();
        }

        String searchName = shoppingItem.getItemName().trim().toLowerCase();
        for (InventoryItem inv : homeInventory) {
            String invName = inv.getName().trim().toLowerCase();
            if (invName.equals(searchName) || invName.contains(searchName) || searchName.contains(invName)) {
                return inv;
            }
            if (shoppingItem.getBarcode() != null && !shoppingItem.getBarcode().isBlank()
                    && shoppingItem.getBarcode().equalsIgnoreCase(inv.getBarcode())) {
                return inv;
            }
        }
        return null;
    }

    private String formatQuantity(BigDecimal qty) {
        if (qty == null) return "0";
        if (qty.stripTrailingZeros().scale() <= 0) {
            return qty.toBigInteger().toString();
        }
        return qty.stripTrailingZeros().toPlainString();
    }
}
