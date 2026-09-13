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
public class BillingPeriodDto {
    private int year;
    private int month;
    private String monthName;
    private long billsCount;
    private BigDecimal totalSpend;
}
