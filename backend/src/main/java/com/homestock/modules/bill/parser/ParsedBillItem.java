package com.homestock.modules.bill.parser;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ParsedBillItem {
    private String name;
    private BigDecimal quantity;
    private String unit;
    private BigDecimal unitPrice;
    private BigDecimal mrp;
    @Builder.Default
    private BigDecimal discount = BigDecimal.ZERO;
    @Builder.Default
    private BigDecimal tax = BigDecimal.ZERO;
    private BigDecimal finalPrice;
    private String barcode;
}
