package com.homestock.modules.consumption.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConfirmQuantityRequest {

    @NotNull(message = "Quantity is required")
    @DecimalMin(value = "0.0", inclusive = true, message = "Quantity cannot be negative")
    private BigDecimal quantity;

    private String unit;
}
