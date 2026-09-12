package com.homestock.modules.deals.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductAvailability {
    private boolean available;
    private String status; // IN_STOCK, OUT_OF_STOCK, LIMITED_STOCK
    private String deliveryStatus;
    private String estimatedDelivery;

    public static ProductAvailability inStock(String estimatedDelivery) {
        return ProductAvailability.builder()
                .available(true)
                .status("IN_STOCK")
                .deliveryStatus("Delivery available")
                .estimatedDelivery(estimatedDelivery)
                .build();
    }

    public static ProductAvailability outOfStock() {
        return ProductAvailability.builder()
                .available(false)
                .status("OUT_OF_STOCK")
                .deliveryStatus("Currently unavailable")
                .build();
    }
}
