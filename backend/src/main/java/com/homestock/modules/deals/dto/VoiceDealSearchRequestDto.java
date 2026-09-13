package com.homestock.modules.deals.dto;

import lombok.*;

import java.math.BigDecimal;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VoiceDealSearchRequestDto {
    private String query; // e.g. "5 kilo ponni arisi cheap ah enga iruku?" or "Nearby shop la oil price paaru"
    private BigDecimal latitude;
    private BigDecimal longitude;
    private Double radiusKm;
}
