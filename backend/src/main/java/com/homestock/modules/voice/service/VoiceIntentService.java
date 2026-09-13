package com.homestock.modules.voice.service;

import com.homestock.modules.voice.dto.VoiceIntent;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.Set;

@Service
public class VoiceIntentService {

    private static final Map<String, VoiceIntent> INTENT_MAPPING = Map.ofEntries(
            // Shopping list
            Map.entry("ADD_TO_SHOPPING_LIST", VoiceIntent.ADD_SHOPPING_ITEM),
            Map.entry("ADD_SHOPPING_ITEM", VoiceIntent.ADD_SHOPPING_ITEM),
            Map.entry("REMOVE_FROM_SHOPPING_LIST", VoiceIntent.REMOVE_SHOPPING_ITEM),
            Map.entry("REMOVE_SHOPPING_ITEM", VoiceIntent.REMOVE_SHOPPING_ITEM),
            Map.entry("UPDATE_SHOPPING_LIST_ITEM", VoiceIntent.UPDATE_SHOPPING_ITEM),
            Map.entry("UPDATE_SHOPPING_ITEM", VoiceIntent.UPDATE_SHOPPING_ITEM),
            Map.entry("COMPLETE_SHOPPING_ITEM", VoiceIntent.COMPLETE_SHOPPING_ITEM),
            Map.entry("CLEAR_SHOPPING_LIST", VoiceIntent.CLEAR_SHOPPING_LIST),
            Map.entry("GET_SHOPPING_LIST", VoiceIntent.GET_SHOPPING_LIST),

            // Inventory & Stock
            Map.entry("ADD_TO_INVENTORY", VoiceIntent.ADD_INVENTORY_ITEM),
            Map.entry("ADD_INVENTORY_ITEM", VoiceIntent.ADD_INVENTORY_ITEM),
            Map.entry("UPDATE_INVENTORY", VoiceIntent.UPDATE_INVENTORY_ITEM),
            Map.entry("UPDATE_INVENTORY_ITEM", VoiceIntent.UPDATE_INVENTORY_ITEM),
            Map.entry("REMOVE_FROM_INVENTORY", VoiceIntent.REMOVE_INVENTORY_ITEM),
            Map.entry("REMOVE_INVENTORY_ITEM", VoiceIntent.REMOVE_INVENTORY_ITEM),
            Map.entry("CONSUME_INVENTORY", VoiceIntent.STOCK_OUT),
            Map.entry("STOCK_OUT", VoiceIntent.STOCK_OUT),
            Map.entry("STOCK_IN", VoiceIntent.STOCK_IN),
            Map.entry("UPDATE_STOCK", VoiceIntent.UPDATE_STOCK),
            Map.entry("GET_INVENTORY", VoiceIntent.GET_ITEM_STATUS),
            Map.entry("GET_ITEM_STATUS", VoiceIntent.GET_ITEM_STATUS),
            Map.entry("SEARCH_INVENTORY", VoiceIntent.SEARCH_INVENTORY),
            Map.entry("GET_LOW_STOCK_ITEMS", VoiceIntent.GET_LOW_STOCK_ITEMS),
            Map.entry("GET_EXPIRING_ITEMS", VoiceIntent.GET_EXPIRING_ITEMS),

            // Product & Search
            Map.entry("SEARCH_PRODUCT", VoiceIntent.SEARCH_PRODUCT),
            Map.entry("GET_PRODUCT_DETAILS", VoiceIntent.GET_PRODUCT_DETAILS),
            Map.entry("SMART_PRICE_CHECK", VoiceIntent.SMART_PRICE_CHECK),

            // Navigation
            Map.entry("OPEN_SHOPPING_LIST", VoiceIntent.OPEN_SHOPPING_LIST),
            Map.entry("OPEN_INVENTORY", VoiceIntent.OPEN_INVENTORY),
            Map.entry("OPEN_ANALYTICS", VoiceIntent.OPEN_ANALYTICS)
    );

    private static final Set<VoiceIntent> PRODUCT_REQUIRED_INTENTS = Set.of(
            VoiceIntent.ADD_SHOPPING_ITEM,
            VoiceIntent.REMOVE_SHOPPING_ITEM,
            VoiceIntent.UPDATE_SHOPPING_ITEM,
            VoiceIntent.ADD_INVENTORY_ITEM,
            VoiceIntent.UPDATE_INVENTORY_ITEM,
            VoiceIntent.REMOVE_INVENTORY_ITEM,
            VoiceIntent.STOCK_IN,
            VoiceIntent.STOCK_OUT,
            VoiceIntent.UPDATE_STOCK,
            VoiceIntent.GET_ITEM_STATUS,
            VoiceIntent.SEARCH_PRODUCT,
            VoiceIntent.GET_PRODUCT_DETAILS
    );

    private static final Set<VoiceIntent> QUANTITY_REQUIRED_INTENTS = Set.of(
            VoiceIntent.STOCK_IN,
            VoiceIntent.STOCK_OUT,
            VoiceIntent.UPDATE_STOCK
    );

    public VoiceIntent parseIntent(String rawIntent) {
        if (rawIntent == null || rawIntent.isBlank()) {
            return VoiceIntent.UNKNOWN;
        }
        String normalized = rawIntent.trim().toUpperCase();
        return INTENT_MAPPING.getOrDefault(normalized, VoiceIntent.UNKNOWN);
    }

    public boolean requiresProduct(VoiceIntent intent) {
        return PRODUCT_REQUIRED_INTENTS.contains(intent);
    }

    public boolean requiresQuantity(VoiceIntent intent) {
        return QUANTITY_REQUIRED_INTENTS.contains(intent);
    }

    public boolean isReadOnly(VoiceIntent intent) {
        return switch (intent) {
            case GET_ITEM_STATUS, GET_SHOPPING_LIST, SEARCH_PRODUCT, GET_PRODUCT_DETAILS,
                    SEARCH_INVENTORY, GET_LOW_STOCK_ITEMS, GET_EXPIRING_ITEMS,
                    OPEN_SHOPPING_LIST, OPEN_INVENTORY, OPEN_ANALYTICS, SMART_PRICE_CHECK -> true;
            default -> false;
        };
    }
}

