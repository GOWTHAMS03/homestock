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
public class BillScanPreviewResponseDto {
    private UUID billId;
    private String shopName;
    private String billNumber;
    private LocalDate billDate;
    private BigDecimal subtotal;
    private BigDecimal tax;
    private BigDecimal discount;
    private BigDecimal total;
    private String currency;
    private boolean isDuplicate;
    private String duplicateWarning;
    private UUID existingBillId;
    @Builder.Default
    private List<BillScanItemPreviewDto> items = new ArrayList<>();
    private int totalItemCount;
    private int autoMatchedCount;
    private int suggestedCount;
    private int newProductCount;
}
