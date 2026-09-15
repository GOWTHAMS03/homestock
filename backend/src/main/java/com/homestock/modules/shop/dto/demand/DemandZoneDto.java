package com.homestock.modules.shop.dto.demand;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DemandZoneDto {
    private String zoneLabel;
    private double minRadiusKm;
    private double maxRadiusKm;
    private long totalEvents;
    private double demandSharePercentage;
    private List<String> topSearchTerms;
}
