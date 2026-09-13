package com.homestock.modules.deals.client;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestTemplate;

import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OverpassClientTest {

    @Mock
    private RestTemplate restTemplate;

    private OverpassClient overpassClient;

    @BeforeEach
    void setUp() {
        overpassClient = new OverpassClient(restTemplate);
    }

    @Test
    @DisplayName("Query Builder: constructs valid Overpass QL with correct categories and radius")
    void testBuildOverpassQuery() {
        String query = overpassClient.buildOverpassQuery(11.7968, 77.8013, 2000);

        assertThat(query).contains("[out:json]");
        assertThat(query).contains("around:2000,11.796800,77.801300");
        assertThat(query).contains("supermarket|convenience|grocery|general|department_store|greengrocer|farm");
        assertThat(query).contains("out center tags;");
    }

    @Test
    @DisplayName("Element Parsing: parses nodes and ways with center coordinates and tags")
    void testParseElements() {
        // Node element with direct lat/lon
        OverpassClient.OverpassElement node = new OverpassClient.OverpassElement();
        node.setType("node");
        node.setId(101L);
        node.setLat(11.7970);
        node.setLon(77.8015);
        Map<String, String> nodeTags = new HashMap<>();
        nodeTags.put("name", "Sri Lakshmi Stores");
        nodeTags.put("shop", "grocery");
        nodeTags.put("addr:street", "Bazaar Street");
        nodeTags.put("addr:city", "Mettur");
        node.setTags(nodeTags);

        // Way element with center object
        OverpassClient.OverpassElement way = new OverpassClient.OverpassElement();
        way.setType("way");
        way.setId(202L);
        OverpassClient.OverpassCenter center = new OverpassClient.OverpassCenter();
        center.setLat(11.7985);
        center.setLon(77.8020);
        way.setCenter(center);
        Map<String, String> wayTags = new HashMap<>();
        wayTags.put("name", "Daily Fresh Supermarket");
        wayTags.put("shop", "supermarket");
        wayTags.put("opening_hours", "08:00-22:00");
        way.setTags(wayTags);

        List<OverpassClient.RawOsmShop> parsed = overpassClient.parseElements(List.of(node, way));

        assertThat(parsed).hasSize(2);

        // Verify node
        OverpassClient.RawOsmShop shop1 = parsed.get(0);
        assertThat(shop1.getOsmId()).isEqualTo("node:101");
        assertThat(shop1.getName()).isEqualTo("Sri Lakshmi Stores");
        assertThat(shop1.getShopType()).isEqualTo("GROCERY");
        assertThat(shop1.getLatitude()).isEqualByComparingTo("11.7970");
        assertThat(shop1.getLongitude()).isEqualByComparingTo("77.8015");
        assertThat(shop1.getAddress()).contains("Bazaar Street");

        // Verify way
        OverpassClient.RawOsmShop shop2 = parsed.get(1);
        assertThat(shop2.getOsmId()).isEqualTo("way:202");
        assertThat(shop2.getName()).isEqualTo("Daily Fresh Supermarket");
        assertThat(shop2.getShopType()).isEqualTo("SUPERMARKET");
        assertThat(shop2.getOpeningHours()).isEqualTo("08:00-22:00");
    }

    @Test
    @DisplayName("Failover: attempts secondary endpoint when primary fails")
    void testFailoverOnPrimaryFailure() {
        OverpassClient.OverpassResponse sampleResponse = new OverpassClient.OverpassResponse();
        OverpassClient.OverpassElement node = new OverpassClient.OverpassElement();
        node.setType("node");
        node.setId(303L);
        node.setLat(11.7950);
        node.setLon(77.8000);
        Map<String, String> tags = Map.of("name", "Failover Provision Store", "shop", "convenience");
        node.setTags(tags);
        sampleResponse.setElements(List.of(node));

        // Primary endpoint throws exception, secondary returns 200 OK
        when(restTemplate.postForEntity(eq("https://overpass-api.de/api/interpreter"), any(HttpEntity.class), eq(OverpassClient.OverpassResponse.class)))
                .thenThrow(new RuntimeException("Connection timeout on primary"));

        when(restTemplate.postForEntity(eq("https://lz4.overpass-api.de/api/interpreter"), any(HttpEntity.class), eq(OverpassClient.OverpassResponse.class)))
                .thenReturn(new ResponseEntity<>(sampleResponse, HttpStatus.OK));

        List<OverpassClient.RawOsmShop> result = overpassClient.fetchNearbyGroceryShops(11.7950, 77.8000, 2000);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getName()).isEqualTo("Failover Provision Store");
        assertThat(result.get(0).getShopType()).isEqualTo("PROVISION");
    }
}

