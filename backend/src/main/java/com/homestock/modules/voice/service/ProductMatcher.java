package com.homestock.modules.voice.service;

import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.voice.dto.DisambiguationOption;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ProductMatcher {

    private final InventoryItemRepository inventoryItemRepository;
    private final TamilTanglishNormalizer tamilTanglishNormalizer;

    public static class MatchResult {
        public InventoryItem exactMatch;
        public List<InventoryItem> ambiguousMatches = new ArrayList<>();
        public boolean isAmbiguous() {
            return ambiguousMatches.size() > 1;
        }
    }

    /**
     * Matches a spoken item name against the active inventory items of a home.
     */
    public MatchResult matchProduct(UUID homeId, String rawItemName) {
        MatchResult result = new MatchResult();
        if (rawItemName == null || rawItemName.isBlank()) {
            return result;
        }

        String normalizedName = tamilTanglishNormalizer.normalizeItemName(rawItemName);
        String targetLower = normalizedName.toLowerCase().trim();

        List<InventoryItem> allItems = inventoryItemRepository.findAll().stream()
                .filter(i -> i.getHome() != null && i.getHome().getId().equals(homeId) && !i.getIsArchived())
                .collect(Collectors.toList());

        // 1. Exact case-insensitive match
        for (InventoryItem item : allItems) {
            if (item.getName().equalsIgnoreCase(normalizedName) || item.getName().equalsIgnoreCase(rawItemName.trim())) {
                result.exactMatch = item;
                return result;
            }
        }

        // 2. Contains / Partial matching
        List<InventoryItem> candidates = new ArrayList<>();
        for (InventoryItem item : allItems) {
            String itemNameLower = item.getName().toLowerCase();
            if (itemNameLower.contains(targetLower) || targetLower.contains(itemNameLower)) {
                candidates.add(item);
            }
        }

        if (candidates.size() == 1) {
            result.exactMatch = candidates.get(0);
        } else if (candidates.size() > 1) {
            result.ambiguousMatches = candidates;
        }

        return result;
    }

    public List<DisambiguationOption> createOptionsFromItems(List<InventoryItem> items) {
        return items.stream().map(item -> DisambiguationOption.builder()
                .id(item.getId().toString())
                .label(item.getName())
                .subLabel(item.getQuantity() + " " + item.getUnit() + " in stock")
                .action("SELECT_ITEM")
                .build()
        ).collect(Collectors.toList());
    }
}
