package com.homestock.modules.deals.dto;

import lombok.*;

import java.math.BigDecimal;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserLocationPreferenceDto {
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String approximateArea;
    private String city;
    private String postalCode;
    private Boolean isManual;
    private BigDecimal preferredRadiusKm;
    private Boolean includeTravelCost;
    private BigDecimal travelCostPerKm;
    private String sortPreference; // CHEAPEST, NEAREST, BEST_VALUE, ONE_STORE, MAX_SAVING
}
