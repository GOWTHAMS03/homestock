package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Summary of the user's requested item in the Deals response.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShoppingItemIntentDto {
    private String name;
    private String brand;
    private BigDecimal requiredQuantity;
    private String unit;
    private String packSize;
}
