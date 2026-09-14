package com.homestock.modules.deals.provider;

import com.homestock.modules.deals.dto.ShopDiscoveryDto;

import java.util.List;

/**
 * Provider interface for modular nearby shop discovery.
 * Ensures initial production uses zero-cost OpenStreetMap with zero paid API dependencies.
 */
public interface ShopDiscoveryProvider {

    List<ShopDiscoveryDto> discoverNearbyShops(double latitude, double longitude, int radiusMeters);

    String getProviderName();

    default boolean isAvailable() {
        return true;
    }
}
