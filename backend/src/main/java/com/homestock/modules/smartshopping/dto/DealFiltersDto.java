package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DealFiltersDto {
    private List<FilterOptionDto> availableTypes;
    private List<FilterOptionDto> availableBrands;
    private List<FilterOptionDto> availablePackSizes;
    private List<FilterOptionDto> availableStores;
}
