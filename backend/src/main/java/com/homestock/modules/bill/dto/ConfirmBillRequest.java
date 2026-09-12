package com.homestock.modules.bill.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConfirmBillRequest {
    private String shopName;
    private String billNumber;
    private LocalDate billDate;
    private BigDecimal subtotal;
    private BigDecimal taxAmount;
    private BigDecimal discountAmount;

    @NotNull(message = "Total amount is required")
    private BigDecimal totalAmount;

    @NotEmpty(message = "Items list cannot be empty")
    @Valid
    private List<ConfirmBillItemRequest> items;

    private String notes;
}
