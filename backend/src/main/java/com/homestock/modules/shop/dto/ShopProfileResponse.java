package com.homestock.modules.shop.dto;

import com.homestock.modules.deals.entity.NearbyShop;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopProfileResponse {
    private UUID id;
    private String name;
    private String ownerName;
    private String shopType;
    private String address;
    private String area;
    private String city;
    private String state;
    private String postalCode;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String phone;
    private String email;
    private String whatsappNumber;
    private BigDecimal rating;
    private Integer reviewCount;
    private String openingHours;
    private LocalTime openingTime;
    private LocalTime closingTime;
    private Boolean isOpen;
    private Boolean isCurrentlyOpen;
    private String verificationStatus;
    private String shopImageUrl;
    private String gstNumber;
    private Integer productCount;
    private Long activeDealCount;
    private Instant lastInventoryUpdate;
    private Double distanceKm;

    // Subscription info (owner-only)
    private String subscriptionPlan;
    private String subscriptionStatus;
    private Integer maxProducts;

    public static ShopProfileResponse fromEntity(NearbyShop shop) {
        return ShopProfileResponse.builder()
                .id(shop.getId())
                .name(shop.getName())
                .ownerName(shop.getOwnerName())
                .shopType(shop.getShopType())
                .address(shop.getAddress())
                .area(shop.getArea())
                .city(shop.getCity())
                .state(shop.getState())
                .postalCode(shop.getPostalCode())
                .latitude(shop.getLatitude())
                .longitude(shop.getLongitude())
                .phone(shop.getPhone())
                .email(shop.getEmail())
                .whatsappNumber(shop.getWhatsappNumber())
                .rating(shop.getRating())
                .reviewCount(shop.getReviewCount())
                .openingHours(shop.getOpeningHours())
                .openingTime(shop.getOpeningTime())
                .closingTime(shop.getClosingTime())
                .isOpen(shop.getIsOpen())
                .isCurrentlyOpen(shop.isCurrentlyOpen())
                .verificationStatus(shop.getVerificationStatus())
                .shopImageUrl(shop.getShopImageUrl())
                .gstNumber(shop.getGstNumber())
                .productCount(shop.getProductCount())
                .lastInventoryUpdate(shop.getLastInventoryUpdate())
                .build();
    }
}
