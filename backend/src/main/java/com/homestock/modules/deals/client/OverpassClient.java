package com.homestock.modules.deals.client;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.util.*;

/**
 * Production-grade OpenStreetMap Overpass API Client.
 * Queries live POIs (supermarkets, convenience stores, grocery shops) around coordinates.
 * Completely free (Zero Google Places / Paid API usage).
 * Resilient failover across public Overpass mirror endpoints.
 */
@Component
public class OverpassClient {

    private static final Logger log = LoggerFactory.getLogger(OverpassClient.class);

    // List of resilient, publicly accessible Overpass interpreter endpoints
    private List<String> overpassEndpoints = List.of(
            "https://overpass-api.de/api/interpreter",
            "https://lz4.overpass-api.de/api/interpreter",
            "https://overpass.kumi.systems/api/interpreter",
            "https://overpass.private.coffee/api/interpreter"
    );

    private final RestTemplate restTemplate;
    private final Map<String, Instant> endpointCooldowns = new java.util.concurrent.ConcurrentHashMap<>();

    @org.springframework.beans.factory.annotation.Value("${app.deals.overpass.circuit-breaker-cooldown-seconds:120}")
    private long cooldownSeconds = 120; // 2 minutes cooldown on failure

    @org.springframework.beans.factory.annotation.Value("${app.deals.overpass.query-timeout-seconds:5}")
    private int queryTimeoutSeconds = 5;

    @Autowired
    public OverpassClient(RestTemplateBuilder restTemplateBuilder,
                          @org.springframework.beans.factory.annotation.Value("${app.deals.overpass.endpoints:https://overpass.kumi.systems/api/interpreter,https://overpass.private.coffee/api/interpreter,https://lz4.overpass-api.de/api/interpreter,https://overpass-api.de/api/interpreter}") String configuredEndpoints) {
        this.restTemplate = restTemplateBuilder
                .setConnectTimeout(Duration.ofSeconds(3))
                .setReadTimeout(Duration.ofSeconds(5))
                .defaultHeader("User-Agent", "HomeStock/1.0 (FreeNearbyShopDiscovery; support@homestock.app)")
                .build();

        if (configuredEndpoints != null && !configuredEndpoints.isBlank()) {
            this.overpassEndpoints = Arrays.stream(configuredEndpoints.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .toList();
        }
    }

    public OverpassClient(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    public OverpassClient(RestTemplate restTemplate, List<String> endpoints) {
        this.restTemplate = restTemplate;
        if (endpoints != null && !endpoints.isEmpty()) {
            this.overpassEndpoints = endpoints;
        }
    }

    public void setOverpassEndpoints(List<String> endpoints) {
        if (endpoints != null && !endpoints.isEmpty()) {
            this.overpassEndpoints = endpoints;
        }
    }

    /**
     * Builds optimized Overpass QL query string for grocery/provision/supermarket shops.
     */
    public String buildOverpassQuery(double latitude, double longitude, int radiusMeters) {
        return String.format(Locale.US,
                "[out:json][timeout:%d];\n" +
                "(\n" +
                "  node[\"shop\"~\"^(supermarket|convenience|grocery|general|department_store|greengrocer|farm)$\"](around:%d,%.6f,%.6f);\n" +
                "  way[\"shop\"~\"^(supermarket|convenience|grocery|general|department_store|greengrocer|farm)$\"](around:%d,%.6f,%.6f);\n" +
                "  relation[\"shop\"~\"^(supermarket|convenience|grocery|general|department_store|greengrocer|farm)$\"](around:%d,%.6f,%.6f);\n" +
                ");\n" +
                "out center tags;",
                queryTimeoutSeconds,
                radiusMeters, latitude, longitude,
                radiusMeters, latitude, longitude,
                radiusMeters, latitude, longitude
        );
    }

    /**
     * Executes Overpass query with circuit-breaker aware failover across mirror endpoints.
     */
    public List<RawOsmShop> fetchNearbyGroceryShops(double latitude, double longitude, int radiusMeters) {
        String query = buildOverpassQuery(latitude, longitude, radiusMeters);

        Instant now = Instant.now();
        List<String> prioritizedEndpoints = new ArrayList<>(overpassEndpoints);
        // Sort: Healthy endpoints first, cooling down endpoints last
        prioritizedEndpoints.sort(Comparator.comparing(ep -> {
            Instant cd = endpointCooldowns.get(ep);
            return (cd != null && cd.isAfter(now)) ? 1 : 0;
        }));

        for (String endpoint : prioritizedEndpoints) {
            Instant cooldownUntil = endpointCooldowns.get(endpoint);
            if (cooldownUntil != null && cooldownUntil.isAfter(now)) {
                log.debug("[OVERPASS] Endpoint {} is in circuit breaker cooldown until {}. Probing as fallback.",
                        endpoint, cooldownUntil);
            }

            try {
                HttpHeaders headers = new HttpHeaders();
                headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
                headers.setAccept(List.of(MediaType.APPLICATION_JSON));
                headers.set("User-Agent", "HomeStock/1.0 (FreeNearbyShopDiscovery; support@homestock.app)");

                MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
                body.add("data", query);

                HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(body, headers);

                ResponseEntity<OverpassResponse> response = restTemplate.postForEntity(
                        endpoint, request, OverpassResponse.class);

                if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                    endpointCooldowns.remove(endpoint); // Clear cooldown on success
                    List<RawOsmShop> parsed = parseElements(response.getBody().getElements());
                    log.info("[OVERPASS] Success from endpoint {}: found {} grocery shops around ({}, {}) radius={}m",
                            endpoint, parsed.size(), latitude, longitude, radiusMeters);
                    return parsed;
                }
            } catch (Exception e) {
                endpointCooldowns.put(endpoint, Instant.now().plusSeconds(cooldownSeconds));
                log.warn("[OVERPASS] Endpoint {} failed with message: {}. Placed in cooldown for {}s. Attempting failover if available.",
                        endpoint, e.getMessage(), cooldownSeconds);
            }
        }

        log.error("[OVERPASS] All mirror endpoints exhausted for ({}, {}) radius={}m", latitude, longitude, radiusMeters);
        return Collections.emptyList();
    }

    /**
     * Parses raw Overpass elements into clean RawOsmShop representations.
     */
    public List<RawOsmShop> parseElements(List<OverpassElement> elements) {
        if (elements == null || elements.isEmpty()) {
            return Collections.emptyList();
        }

        List<RawOsmShop> shops = new ArrayList<>();

        for (OverpassElement elem : elements) {
            BigDecimal lat = null;
            BigDecimal lon = null;

            if (elem.getLat() != null && elem.getLon() != null) {
                lat = BigDecimal.valueOf(elem.getLat()).setScale(7, RoundingMode.HALF_UP);
                lon = BigDecimal.valueOf(elem.getLon()).setScale(7, RoundingMode.HALF_UP);
            } else if (elem.getCenter() != null && elem.getCenter().getLat() != null && elem.getCenter().getLon() != null) {
                lat = BigDecimal.valueOf(elem.getCenter().getLat()).setScale(7, RoundingMode.HALF_UP);
                lon = BigDecimal.valueOf(elem.getCenter().getLon()).setScale(7, RoundingMode.HALF_UP);
            }

            if (lat == null || lon == null) {
                continue;
            }

            Map<String, String> tags = elem.getTags() != null ? elem.getTags() : Collections.emptyMap();
            String name = tags.get("name");
            if (name == null || name.isBlank()) {
                name = tags.get("name:en");
            }
            if (name == null || name.isBlank()) {
                name = tags.get("brand");
            }

            String shopTypeTag = tags.getOrDefault("shop", "grocery").toLowerCase();
            String normalizedCategory;
            switch (shopTypeTag) {
                case "supermarket" -> normalizedCategory = "SUPERMARKET";
                case "convenience" -> normalizedCategory = "PROVISION";
                case "department_store" -> normalizedCategory = "DEPARTMENT";
                case "greengrocer", "farm" -> normalizedCategory = "GROCERY";
                default -> normalizedCategory = "GROCERY";
            }

            // If name is still missing, provide a clean descriptive fallback
            if (name == null || name.isBlank()) {
                name = "Local " + capitalize(shopTypeTag) + " Shop";
            }

            String street = tags.get("addr:street");
            String suburb = tags.get("addr:suburb");
            String city = tags.get("addr:city");
            String postcode = tags.get("addr:postcode");

            StringBuilder addressBuilder = new StringBuilder();
            if (street != null && !street.isBlank()) addressBuilder.append(street.trim());
            if (suburb != null && !suburb.isBlank()) {
                if (!addressBuilder.isEmpty()) addressBuilder.append(", ");
                addressBuilder.append(suburb.trim());
            }
            if (city != null && !city.isBlank()) {
                if (!addressBuilder.isEmpty()) addressBuilder.append(", ");
                addressBuilder.append(city.trim());
            }

            String fullAddress = !addressBuilder.isEmpty() ? addressBuilder.toString() : (city != null ? city : "Local Area");

            shops.add(RawOsmShop.builder()
                    .osmId(elem.getType() + ":" + elem.getId())
                    .osmType(elem.getType())
                    .name(name.trim())
                    .shopType(normalizedCategory)
                    .rawShopTag(shopTypeTag)
                    .address(fullAddress)
                    .area(suburb != null ? suburb.trim() : "")
                    .city(city != null ? city.trim() : "")
                    .postalCode(postcode != null ? postcode.trim() : "")
                    .latitude(lat)
                    .longitude(lon)
                    .openingHours(tags.get("opening_hours"))
                    .phone(tags.containsKey("phone") ? tags.get("phone") : tags.get("contact:phone"))
                    .website(tags.containsKey("website") ? tags.get("website") : tags.get("contact:website"))
                    .brand(tags.get("brand"))
                    .build());
        }

        return shops;
    }

    private String capitalize(String text) {
        if (text == null || text.isEmpty()) return "";
        return Character.toUpperCase(text.charAt(0)) + text.substring(1).toLowerCase();
    }

    // --- Inner Models for Overpass JSON mapping ---

    @Getter
    @Setter
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class OverpassResponse {
        private List<OverpassElement> elements;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class OverpassElement {
        private String type; // node, way, relation
        private Long id;
        private Double lat;
        private Double lon;
        private OverpassCenter center;
        private Map<String, String> tags;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class OverpassCenter {
        private Double lat;
        private Double lon;
    }

    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RawOsmShop {
        private String osmId;
        private String osmType;
        private String name;
        private String shopType;
        private String rawShopTag;
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
    }
}

