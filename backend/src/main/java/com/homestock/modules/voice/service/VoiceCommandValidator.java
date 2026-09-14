package com.homestock.modules.voice.service;

import com.homestock.core.security.HomeSecurityService;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.entity.StockTransaction;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.inventory.repository.StockTransactionRepository;
import com.homestock.modules.voice.dto.QuantityConfirmationInfo;
import com.homestock.modules.voice.dto.VoiceCommandResult;
import com.homestock.modules.voice.dto.VoiceEntities;
import com.homestock.modules.voice.dto.VoiceIntent;
import lombok.Builder;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
public class VoiceCommandValidator {

    private final HomeSecurityService homeSecurityService;
    private final VoiceIntentService voiceIntentService;
    private final InventoryItemRepository inventoryItemRepository;
    private final StockTransactionRepository stockTransactionRepository;
    private final UnitNormalizationService unitNormalizer;

    @Autowired
    public VoiceCommandValidator(HomeSecurityService homeSecurityService,
                                 VoiceIntentService voiceIntentService,
                                 @Autowired(required = false) InventoryItemRepository inventoryItemRepository,
                                 @Autowired(required = false) StockTransactionRepository stockTransactionRepository,
                                 @Autowired(required = false) UnitNormalizationService unitNormalizer) {
        this.homeSecurityService = homeSecurityService;
        this.voiceIntentService = voiceIntentService;
        this.inventoryItemRepository = inventoryItemRepository;
        this.stockTransactionRepository = stockTransactionRepository;
        this.unitNormalizer = unitNormalizer != null ? unitNormalizer : new UnitNormalizationService();
    }

    public VoiceCommandValidator(HomeSecurityService homeSecurityService, VoiceIntentService voiceIntentService) {
        this(homeSecurityService, voiceIntentService, null, null, new UnitNormalizationService());
    }

    @Data
    @Builder
    public static class ValidationResult {
        private boolean valid;
        private String errorMessage;
        private boolean requiresConfirmation;
        private String confirmationPrompt;
        private QuantityConfirmationInfo quantityConfirmation;

        public static ValidationResult ok() {
            return ValidationResult.builder().valid(true).build();
        }

        public static ValidationResult error(String msg) {
            return ValidationResult.builder().valid(false).errorMessage(msg).build();
        }

        public static ValidationResult confirmation(String prompt) {
            return ValidationResult.builder()
                    .valid(true)
                    .requiresConfirmation(true)
                    .confirmationPrompt(prompt)
                    .build();
        }

        public static ValidationResult quantityConfirmation(QuantityConfirmationInfo info) {
            String prompt = String.format("%s %s %s (Quantity %s %s seems unusually large. Confirm to proceed?)",
                    info.getPromptTitle(),
                    info.getPromptCurrent(),
                    info.getPromptProjected(),
                    info.getRequestedQuantity() != null ? info.getRequestedQuantity().stripTrailingZeros().toPlainString() : "",
                    info.getRequestedUnit() != null ? info.getRequestedUnit().toLowerCase() : "");
            return ValidationResult.builder()
                    .valid(true)
                    .requiresConfirmation(true)
                    .confirmationPrompt(prompt)
                    .quantityConfirmation(info)
                    .build();
        }
    }

    public ValidationResult validate(UUID homeId, VoiceCommandResult command) {
        if (homeId == null) {
            return ValidationResult.error("Home context is missing");
        }

        // 1. Authorization check
        if (!homeSecurityService.isMember(homeId)) {
            return ValidationResult.error("Access denied: You are not a member of this home");
        }

        VoiceIntent intent = command.getIntent();
        if (intent == null || intent == VoiceIntent.UNKNOWN) {
            return ValidationResult.error("Could not determine command intent");
        }

        // Check permission based on intent
        if (!checkIntentPermission(homeId, intent)) {
            return ValidationResult.error("You do not have permission to perform this action");
        }

        VoiceEntities entities = command.getEntities();

        // 2. Product requirement
        if (voiceIntentService.requiresProduct(intent)) {
            if (entities == null || (entities.getItemName() == null && entities.getMatchedInventoryItemId() == null)) {
                return ValidationResult.error("Product name was not recognized");
            }
        }

        // 3. Quantity sanity check
        if (entities != null && entities.getQuantity() != null) {
            BigDecimal qty = entities.getQuantity();
            if (qty.compareTo(BigDecimal.ZERO) <= 0) {
                return ValidationResult.error("Quantity must be greater than zero");
            }

            ValidationResult sanityResult = validateQuantitySanity(homeId, command);
            if (!sanityResult.isValid() || sanityResult.isRequiresConfirmation()) {
                return sanityResult;
            }
        } else if (voiceIntentService.requiresQuantity(intent)) {
            return ValidationResult.error("Quantity is required for this operation");
        }

        // 4. Large impact operations confirmation (e.g. CLEAR_SHOPPING_LIST)
        if (intent == VoiceIntent.CLEAR_SHOPPING_LIST) {
            return ValidationResult.confirmation("Are you sure you want to clear your entire shopping list?");
        }

        return ValidationResult.ok();
    }

    public ValidationResult validateQuantitySanity(UUID homeId, VoiceCommandResult command) {
        VoiceEntities entities = command.getEntities();
        if (entities == null || entities.getQuantity() == null) {
            return ValidationResult.ok();
        }

        BigDecimal requestedQty = entities.getQuantity();
        String requestedUnit = entities.getUnit() != null ? unitNormalizer.normalize(entities.getUnit()) : "PCS";
        String action = resolveAction(command);

        String prodName = entities.getMatchedInventoryItemName() != null
                ? entities.getMatchedInventoryItemName()
                : (entities.getItemName() != null ? entities.getItemName() : "Item");

        // Resolve existing inventory item if repository is available
        InventoryItem existingItem = resolveExistingItem(homeId, entities);

        if (existingItem != null) {
            String itemUnit = unitNormalizer.normalize(existingItem.getUnit());
            BigDecimal currentQty = existingItem.getQuantity() != null ? existingItem.getQuantity() : BigDecimal.ZERO;

            // Unit compatibility check
            if (!unitNormalizer.areCompatible(requestedUnit, itemUnit)) {
                return ValidationResult.error(String.format(
                        "Cannot convert %s to %s for %s. Measurement types are incompatible.",
                        requestedUnit, itemUnit, existingItem.getName()
                ));
            }

            BigDecimal convertedQty;
            try {
                convertedQty = unitNormalizer.convert(requestedQty, requestedUnit, itemUnit);
            } catch (Exception e) {
                return ValidationResult.error(e.getMessage());
            }

            // Calculate projected new stock
            BigDecimal projectedQty = switch (action.toUpperCase()) {
                case "REMOVE" -> currentQty.subtract(convertedQty).max(BigDecimal.ZERO);
                case "SET" -> convertedQty;
                case "ADD" -> currentQty.add(convertedQty);
                default -> currentQty.add(convertedQty);
            };

            // Check if quantity is unusually high
            boolean isUnusuallyHigh = checkUnusuallyHigh(convertedQty, itemUnit, currentQty, existingItem.getId());

            if (isUnusuallyHigh) {
                String reqUnitDisplay = requestedUnit.toLowerCase();
                String itemUnitDisplay = itemUnit.toLowerCase();
                String capitalizedProd = capitalize(prodName);

                String reqStr = requestedQty.stripTrailingZeros().toPlainString() + " " + reqUnitDisplay;
                String curStr = currentQty.stripTrailingZeros().toPlainString() + " " + itemUnitDisplay;
                String projStr = projectedQty.stripTrailingZeros().toPlainString() + " " + itemUnitDisplay;

                String title = switch (action.toUpperCase()) {
                    case "REMOVE" -> String.format("Remove %s of %s?", reqStr, capitalizedProd);
                    case "SET" -> String.format("Set %s stock to %s?", capitalizedProd, reqStr);
                    default -> String.format("Add %s of %s?", reqStr, capitalizedProd);
                };

                QuantityConfirmationInfo info = QuantityConfirmationInfo.builder()
                        .action(action)
                        .productName(capitalizedProd)
                        .requestedQuantity(requestedQty)
                        .requestedUnit(requestedUnit)
                        .currentQuantity(currentQty)
                        .currentUnit(itemUnit)
                        .projectedQuantity(projectedQty)
                        .promptTitle(title)
                        .promptCurrent(String.format("You currently have %s.", curStr))
                        .promptProjected(String.format("Your new stock will be %s.", projStr))
                        .warningReason(String.format("Quantity (%s) is unusually high for typical household stock.", reqStr))
                        .build();

                return ValidationResult.quantityConfirmation(info);
            }
        } else {
            // New item or item not in inventory yet
            boolean isHigh = isExceedingHouseholdThreshold(requestedQty, requestedUnit);
            if (isHigh) {
                String capitalizedProd = capitalize(prodName);
                String reqUnitDisplay = requestedUnit.toLowerCase();
                String reqStr = requestedQty.stripTrailingZeros().toPlainString() + " " + reqUnitDisplay;

                String title = switch (action.toUpperCase()) {
                    case "REMOVE" -> String.format("Remove %s of %s?", reqStr, capitalizedProd);
                    case "SET" -> String.format("Set %s stock to %s?", capitalizedProd, reqStr);
                    default -> String.format("Add %s of %s?", reqStr, capitalizedProd);
                };

                QuantityConfirmationInfo info = QuantityConfirmationInfo.builder()
                        .action(action)
                        .productName(capitalizedProd)
                        .requestedQuantity(requestedQty)
                        .requestedUnit(requestedUnit)
                        .currentQuantity(BigDecimal.ZERO)
                        .currentUnit(requestedUnit)
                        .projectedQuantity(requestedQty)
                        .promptTitle(title)
                        .promptCurrent(String.format("You currently have 0 %s.", reqUnitDisplay))
                        .promptProjected(String.format("Your new stock will be %s.", reqStr))
                        .warningReason(String.format("Quantity (%s) is unusually high for a single household addition.", reqStr))
                        .build();

                return ValidationResult.quantityConfirmation(info);
            }
        }

        return ValidationResult.ok();
    }

    private boolean checkUnusuallyHigh(BigDecimal convertedQty, String unit, BigDecimal currentQty, UUID itemId) {
        // 1. Exceeds standard household pantry threshold
        if (isExceedingHouseholdThreshold(convertedQty, unit)) {
            return true;
        }

        // 2. Unusually high relative to current stock (> 5x current stock, with minimum baseline)
        if (currentQty.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal fiveTimesCurrent = currentQty.multiply(BigDecimal.valueOf(5));
            BigDecimal baselineThreshold = getBaselineThreshold(unit);
            if (convertedQty.compareTo(fiveTimesCurrent) > 0 && convertedQty.compareTo(baselineThreshold) > 0) {
                return true;
            }
        }

        // 3. Unusually high relative to historical purchase transactions
        if (itemId != null && stockTransactionRepository != null) {
            try {
                List<StockTransaction> txs = stockTransactionRepository.findTop20ByItemIdOrderByCreatedAtDesc(itemId);
                if (txs != null && !txs.isEmpty()) {
                    BigDecimal maxHistorical = txs.stream()
                            .map(StockTransaction::getQuantityChange)
                            .filter(q -> q != null && q.compareTo(BigDecimal.ZERO) > 0)
                            .max(BigDecimal::compareTo)
                            .orElse(BigDecimal.ZERO);

                    if (maxHistorical.compareTo(BigDecimal.ZERO) > 0) {
                        BigDecimal threeTimesHistorical = maxHistorical.multiply(BigDecimal.valueOf(3));
                        if (convertedQty.compareTo(threeTimesHistorical) > 0 && convertedQty.compareTo(getBaselineThreshold(unit)) > 0) {
                            return true;
                        }
                    }
                }
            } catch (Exception e) {
                log.debug("Could not query historical stock transactions: {}", e.getMessage());
            }
        }

        return false;
    }

    private boolean isExceedingHouseholdThreshold(BigDecimal qty, String unit) {
        String norm = unitNormalizer.normalize(unit);
        UnitNormalizationService.UnitDimension dim = unitNormalizer.getDimension(norm);

        BigDecimal threshold = switch (dim) {
            case MASS -> "G".equalsIgnoreCase(norm) ? BigDecimal.valueOf(10000) : BigDecimal.valueOf(25);
            case VOLUME -> "ML".equalsIgnoreCase(norm) ? BigDecimal.valueOf(15000) : BigDecimal.valueOf(15);
            case COUNT -> BigDecimal.valueOf(30);
            case UNKNOWN -> BigDecimal.valueOf(100);
        };

        return qty.compareTo(threshold) > 0;
    }

    private BigDecimal getBaselineThreshold(String unit) {
        String norm = unitNormalizer.normalize(unit);
        UnitNormalizationService.UnitDimension dim = unitNormalizer.getDimension(norm);
        return switch (dim) {
            case MASS -> "G".equalsIgnoreCase(norm) ? BigDecimal.valueOf(2000) : BigDecimal.valueOf(5);
            case VOLUME -> "ML".equalsIgnoreCase(norm) ? BigDecimal.valueOf(2000) : BigDecimal.valueOf(3);
            case COUNT -> BigDecimal.valueOf(10);
            case UNKNOWN -> BigDecimal.valueOf(20);
        };
    }

    private String resolveAction(VoiceCommandResult command) {
        if (command.getAction() != null && !command.getAction().isBlank()) {
            return command.getAction().toUpperCase();
        }
        if (command.getEntities() != null && command.getEntities().getAction() != null) {
            return command.getEntities().getAction().toUpperCase();
        }
        VoiceIntent intent = command.getIntent();
        if (intent == null) return "ADD";
        return switch (intent) {
            case STOCK_OUT, REMOVE_INVENTORY_ITEM, REMOVE_SHOPPING_ITEM -> "REMOVE";
            case UPDATE_STOCK, UPDATE_INVENTORY_ITEM -> "SET";
            default -> "ADD";
        };
    }

    private InventoryItem resolveExistingItem(UUID homeId, VoiceEntities entities) {
        if (inventoryItemRepository == null || homeId == null) return null;

        if (entities.getMatchedInventoryItemId() != null) {
            Optional<InventoryItem> opt = inventoryItemRepository.findByIdAndHomeId(entities.getMatchedInventoryItemId(), homeId);
            if (opt.isPresent()) return opt.get();
        }

        String itemName = entities.getItemName();
        if (itemName != null && !itemName.isBlank()) {
            List<InventoryItem> items = inventoryItemRepository.findAllByHomeIdOrderByNameAsc(homeId);
            for (InventoryItem i : items) {
                if (i.getName().equalsIgnoreCase(itemName.trim())) {
                    return i;
                }
            }
            // Partial match fallback
            for (InventoryItem i : items) {
                if (i.getName().toLowerCase().contains(itemName.trim().toLowerCase())
                        || itemName.trim().toLowerCase().contains(i.getName().toLowerCase())) {
                    return i;
                }
            }
        }

        return null;
    }

    private String capitalize(String text) {
        if (text == null || text.isBlank()) return text;
        return Character.toUpperCase(text.charAt(0)) + text.substring(1);
    }

    private boolean checkIntentPermission(UUID homeId, VoiceIntent intent) {
        return switch (intent) {
            case ADD_SHOPPING_ITEM, REMOVE_SHOPPING_ITEM, UPDATE_SHOPPING_ITEM, COMPLETE_SHOPPING_ITEM, CLEAR_SHOPPING_LIST ->
                    homeSecurityService.canEditShoppingList(homeId);
            case ADD_INVENTORY_ITEM, UPDATE_INVENTORY_ITEM, REMOVE_INVENTORY_ITEM, STOCK_IN, STOCK_OUT, UPDATE_STOCK ->
                    homeSecurityService.canManageInventory(homeId);
            default -> true; // Read-only intents require only membership
        };
    }
}


