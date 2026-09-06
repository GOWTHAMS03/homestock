package com.homestock.modules.inventory.dto;

import com.homestock.modules.inventory.entity.TransactionType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class StockUpdateRequest {
    @NotNull(message = "Transaction type is required")
    private TransactionType transactionType;

    @NotNull(message = "Quantity change is required")
    @DecimalMin(value = "0.001", message = "Quantity change must be greater than zero")
    private BigDecimal quantityChange;

    private String reason;
}
