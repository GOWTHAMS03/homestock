package com.homestock.modules.bill.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MonthlyBillSummaryDto {
    private UUID id;
    private String shopName;
    private String billNumber;
    private LocalDate billDate;
    private BigDecimal totalAmount;
    private BigDecimal subtotal;
    private BigDecimal taxAmount;
    private BigDecimal discountAmount;
    private int itemsCount;
    private String status;
    private String source;
    @Builder.Default
    private List<BillItemSummaryDto> items = new ArrayList<>();
}
