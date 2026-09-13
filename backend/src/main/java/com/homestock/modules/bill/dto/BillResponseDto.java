package com.homestock.modules.bill.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BillResponseDto {
    private UUID id;
    private UUID homeId;
    private String shopName;
    private String billNumber;
    private LocalDate billDate;
    private BigDecimal subtotal;
    private BigDecimal taxAmount;
    private BigDecimal discountAmount;
    private BigDecimal totalAmount;
    private String currency;
    private String status;
    private String receiptImageUrl;
    private UUID recordedByUserId;
    private String recordedByName;
    private Instant confirmedAt;
    private Instant createdAt;

    // AI Pipeline fields
    private String processingStatus;
    private BigDecimal overallConfidence;
    private boolean needsReview;
    private String validationStatus;

    @Builder.Default
    private List<BillItemResponseDto> items = new ArrayList<>();
}
