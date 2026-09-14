package com.homestock.modules.deals.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateShopRequestDto {

    @NotBlank(message = "Shop name is required")
    private String name;

    @Builder.Default
    private String shopType = "GROCERY"; // SUPERMARKET, GROCERY, PROVISION, WHOLESALE, DEPARTMENT, BAKERY, BUTCHER

    private String address;
    private String area;

    @NotBlank(message = "City is required")
    private String city;

    private String state;
    private String postalCode;

    @NotNull(message = "Latitude is required")
    @DecimalMin(value = "-90.0", message = "Latitude must be >= -90.0")
    @DecimalMax(value = "90.0", message = "Latitude must be <= 90.0")
    private BigDecimal latitude;

    @NotNull(message = "Longitude is required")
    @DecimalMin(value = "-180.0", message = "Longitude must be >= -180.0")
    @DecimalMax(value = "180.0", message = "Longitude must be <= 180.0")
    private BigDecimal longitude;

    private String phone;
    private String openingHours;
}
