package com.homestock.modules.bill.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CategoryExpenseDto {
    private String categoryName;
    private BigDecimal totalAmount;
    private BigDecimal spendingPercentage;
    private long purchaseCount;
    private BigDecimal quantityPurchased;
}
