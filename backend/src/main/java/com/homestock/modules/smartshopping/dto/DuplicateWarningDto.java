package com.homestock.modules.smartshopping.dto;

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
public class DuplicateWarningDto {
    private UUID shoppingItemId;
    private String itemName;
    private BigDecimal existingStockQuantity;
    private String existingStockUnit;
    private Double estimatedDaysRemaining;
    private String message;
}
