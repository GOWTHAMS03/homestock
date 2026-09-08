package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BasketComparisonResponse {
    private List<BasketOptionDto> options;
    private BasketOptionDto recommendedOption;
    private List<DuplicateWarningDto> duplicateWarnings;
    private Instant calculatedAt;
}
