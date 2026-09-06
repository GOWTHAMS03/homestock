package com.homestock.modules.dashboard.dto;

import com.homestock.modules.inventory.entity.ExpiryStatus;
import com.homestock.modules.inventory.entity.StockStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NeedsAttentionItemDto {
    private UUID itemId;
    private String name;
    private String categoryName;
    private BigDecimal quantity;
    private String unit;
    private StockStatus stockStatus;
    private ExpiryStatus expiryStatus;
    private LocalDate expiryDate;
    private Long daysUntilExpiry;
    private String reasonMessage; // e.g. "Cooking Oil is running low", "Bread expires tomorrow"
}
