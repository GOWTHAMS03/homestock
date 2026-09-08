package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateSessionRequest {
    private List<UUID> itemIds;
    private String selectedProviders;
    private BigDecimal estimatedTotal;
    private String recommendedOption;
}
