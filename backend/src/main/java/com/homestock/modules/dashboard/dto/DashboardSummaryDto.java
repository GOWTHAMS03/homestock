package com.homestock.modules.dashboard.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DashboardSummaryDto {
    private String homeName;
    private long totalInventoryItems;
    private long lowStockCount;
    private long outOfStockCount;
    private long pendingShoppingCount;
    private long expiringSoonCount;
    private List<NeedsAttentionItemDto> needsAttention;
}
