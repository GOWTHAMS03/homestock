package com.homestock.modules.voice.service;

import com.homestock.core.security.HomeSecurityService;
import com.homestock.modules.voice.dto.VoiceCommandResult;
import com.homestock.modules.voice.dto.VoiceEntities;
import com.homestock.modules.voice.dto.VoiceIntent;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class VoiceCommandValidator {

    private final HomeSecurityService homeSecurityService;
    private final VoiceIntentService voiceIntentService;

    private static final BigDecimal MAX_REASONABLE_QUANTITY = new BigDecimal("1000");

    @Data
    @Builder
    public static class ValidationResult {
        private boolean valid;
        private String errorMessage;
        private boolean requiresConfirmation;
        private String confirmationPrompt;

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
            if (qty.compareTo(MAX_REASONABLE_QUANTITY) > 0) {
                return ValidationResult.confirmation("Quantity " + qty + " seems unusually large. Confirm to proceed?");
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

