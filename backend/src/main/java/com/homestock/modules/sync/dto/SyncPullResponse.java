package com.homestock.modules.sync.dto;

import lombok.*;

import java.util.List;
import java.util.Map;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SyncPullResponse {
    private List<Map<String, Object>> inventoryItems;
    private List<Map<String, Object>> stockTransactions;
    private List<Map<String, Object>> shoppingListItems;
    private List<Map<String, Object>> shoppingLists;
    private List<Map<String, Object>> purchases;
    private List<Map<String, Object>> categories;
    private List<Map<String, Object>> stores;
    private String serverTimestamp;

    // Incremental cursor and deletion synchronization
    private Long serverVersion;
    private Long nextServerVersion;
    private Boolean hasMore;
    private List<String> deletedShoppingItemIds;
    private List<String> deletedInventoryItemIds;
    private List<String> deletedStoreIds;
    private List<String> deletedCategoryIds;
}
