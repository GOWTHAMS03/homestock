package com.homestock.modules.shop.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopRegistrationRequest {

    @NotBlank(message = "Shop name is required")
    @Size(max = 150)
    private String shopName;

    @NotBlank(message = "Owner name is required")
    @Size(max = 120)
    private String ownerName;

    @NotBlank(message = "Phone number is required")
    @Size(max = 50)
    private String phone;

    @Size(max = 180)
    private String email;

    @Size(max = 300)
    private String address;

    @NotNull(message = "Latitude is required")
    @DecimalMin(value = "-90.0")
    @DecimalMax(value = "90.0")
    private BigDecimal latitude;

    @NotNull(message = "Longitude is required")
    @DecimalMin(value = "-180.0")
    @DecimalMax(value = "180.0")
    private BigDecimal longitude;

    @Size(max = 100)
    private String area;

    @Size(max = 100)
    private String city;

    @Size(max = 100)
    private String state;

    @Size(max = 20)
    private String postalCode;

    private LocalTime openingTime;
    private LocalTime closingTime;

    @Size(max = 50)
    private String shopType; // SUPERMARKET, GROCERY, PROVISION, etc.

    @Size(max = 50)
    private String shopCategory;

    @Size(max = 512)
    private String shopImageUrl;

    @Size(max = 30)
    private String gstNumber;

    @Size(max = 30)
    private String whatsappNumber;
}
