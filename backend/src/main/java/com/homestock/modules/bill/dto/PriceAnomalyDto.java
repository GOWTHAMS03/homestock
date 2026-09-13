package com.homestock.modules.bill.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PriceAnomalyDto {
    private UUID productId;
    private UUID inventoryItemId;
    private String productName;
    private String category;
    private BigDecimal currentPrice;
    private BigDecimal previousPrice;
    private BigDecimal percentageChange;
    private String unit;
    private String alertType; // PRICE_HIKE, PRICE_DROP
    private String storeName;
    private String detectedAt;
}
