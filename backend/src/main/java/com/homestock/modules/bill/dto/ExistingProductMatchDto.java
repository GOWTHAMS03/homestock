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
public class ExistingProductMatchDto {
    private UUID productId;
    private UUID inventoryItemId;
    private String productName;
    private String category;
    private BigDecimal currentStock;
    private String unit;
    private BigDecimal matchScore;
}
