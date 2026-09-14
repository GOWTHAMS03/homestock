package com.homestock.modules.deals.provider;

import com.homestock.modules.deals.client.OverpassClient;
import com.homestock.modules.deals.dto.ShopDiscoveryDto;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

/**
 * OpenStreetMap Overpass API implementation of ShopDiscoveryProvider.
 * Completely free, queries live OSM data across public mirror endpoints.
 */
@Component
@RequiredArgsConstructor
public class OsmOverpassShopDiscoveryProvider implements ShopDiscoveryProvider {

    private static final Logger log = LoggerFactory.getLogger(OsmOverpassShopDiscoveryProvider.class);

    private final OverpassClient overpassClient;

    @Override
    public List<ShopDiscoveryDto> discoverNearbyShops(double latitude, double longitude, int radiusMeters) {
        if (overpassClient == null) {
            return Collections.emptyList();
        }

        try {
            List<OverpassClient.RawOsmShop> rawShops = overpassClient.fetchNearbyGroceryShops(
                    latitude, longitude, radiusMeters);

            return rawShops.stream().map(raw -> ShopDiscoveryDto.builder()
                    .sourceId(raw.getOsmId())
                    .name(raw.getName())
                    .shopType(raw.getShopType() != null ? raw.getShopType() : "GROCERY")
                    .address(raw.getAddress())
                    .area(raw.getArea())
                    .city(raw.getCity())
                    .postalCode(raw.getPostalCode())
                    .latitude(raw.getLatitude())
                    .longitude(raw.getLongitude())
                    .openingHours(raw.getOpeningHours())
                    .phone(raw.getPhone())
                    .website(raw.getWebsite())
                    .brand(raw.getBrand())
                    .source("OSM")
                    .build()
            ).collect(Collectors.toList());
        } catch (Exception e) {
            log.warn("[OSM_PROVIDER] Error fetching from Overpass for ({}, {}): {}",
                    latitude, longitude, e.getMessage());
            return Collections.emptyList();
        }
    }

    @Override
    public String getProviderName() {
        return "OpenStreetMap-Overpass";
    }
}
