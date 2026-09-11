package com.homestock.modules.away.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PredictionCorrectRequest {

    @NotNull(message = "Actual quantity is required")
    @PositiveOrZero(message = "Actual quantity must be zero or positive")
    private BigDecimal actualQuantity;
}
