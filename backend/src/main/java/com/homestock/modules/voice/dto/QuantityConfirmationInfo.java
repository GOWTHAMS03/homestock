package com.homestock.modules.voice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class QuantityConfirmationInfo {
    private String action; // "ADD", "REMOVE", "SET"
    private String productName;
    private BigDecimal requestedQuantity;
    private String requestedUnit;
    private BigDecimal currentQuantity;
    private String currentUnit;
    private BigDecimal projectedQuantity;
    private String promptTitle;
    private String promptCurrent;
    private String promptProjected;
    private String warningReason;
}
