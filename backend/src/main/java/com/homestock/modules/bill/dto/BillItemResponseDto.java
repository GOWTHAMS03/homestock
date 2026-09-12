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
public class BillItemResponseDto {
    private UUID id;
    private UUID productId;
    private UUID inventoryItemId;
    private UUID shoppingListItemId;
    private String rawItemName;
    private String normalizedItemName;
    private BigDecimal quantity;
    private String unit;
    private BigDecimal mrp;
    private BigDecimal unitPrice;
    private BigDecimal discount;
    private BigDecimal tax;
    private BigDecimal finalPrice;
    private BigDecimal standardUnitPrice;
    private BigDecimal matchConfidence;
    private String matchStatus;
}
