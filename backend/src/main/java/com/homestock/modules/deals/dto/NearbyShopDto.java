package com.homestock.modules.deals.dto;

import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NearbyShopDto {
    private UUID id;
    private String name;
    private String shopType;
    private String address;
    private String area;
    private String city;
    private String postalCode;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private Double distanceKm;
    private String distanceLabel;
    private BigDecimal rating;
    private Integer reviewCount;
    private String openingHours;
    private Boolean isOpen;
    private Boolean isVerified;
    private Integer availableDealsCount;
    private BigDecimal estimatedBasketTotal;
}
