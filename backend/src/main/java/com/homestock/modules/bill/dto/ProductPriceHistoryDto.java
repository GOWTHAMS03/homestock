package com.homestock.modules.bill.dto;

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
public class ProductPriceHistoryDto {
    private UUID id;
    private LocalDate purchaseDate;
    private String storeName;
    private BigDecimal quantity;
    private String unit;
    private BigDecimal unitPrice;
    private BigDecimal standardUnitPrice;
    private BigDecimal totalPrice;
    private boolean isHigherThanUsual;
}
