package com.homestock.modules.bill.parser;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ParsedBill {
    private String shopName;
    private String billNumber;
    private LocalDate billDate;
    @Builder.Default
    private List<ParsedBillItem> items = new ArrayList<>();
    private BigDecimal subtotal;
    @Builder.Default
    private BigDecimal tax = BigDecimal.ZERO;
    @Builder.Default
    private BigDecimal discount = BigDecimal.ZERO;
    private BigDecimal total;
    private String rawText;
}
