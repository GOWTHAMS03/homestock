package com.homestock.modules.deals.dto;

import lombok.*;

import java.math.BigDecimal;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopDiscoveryDto {
    private String sourceId;
    private String name;
    private String shopType;
    private String address;
    private String area;
    private String city;
    private String postalCode;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String openingHours;
    private String phone;
    private String website;
    private String brand;
    private String source;
}
