package com.homestock.modules.product.provider;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.homestock.modules.product.dto.ProductDto;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

@Component
public class OpenFoodFactsProductProvider implements ProductDataProvider {

    private static final Logger log = LoggerFactory.getLogger(OpenFoodFactsProductProvider.class);
    private static final String OFF_API_URL = "https://world.openfoodfacts.org/api/v2/product/%s.json";

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public OpenFoodFactsProductProvider(RestTemplateBuilder builder, ObjectMapper objectMapper) {
        this.restTemplate = builder
                .setConnectTimeout(Duration.ofSeconds(2))
                .setReadTimeout(Duration.ofSeconds(3))
                .build();
        this.objectMapper = objectMapper;
    }

    @Override
    public String getProviderName() {
        return "OPEN_FOOD_FACTS";
    }

    @Override
    public int getPriority() {
        return 3;
    }

    @Override
    public Optional<ProductDto> findByBarcode(String barcode) {
        if (barcode == null || barcode.length() < 8) {
            return Optional.empty();
        }

        try {
            String url = String.format(OFF_API_URL, barcode);
            HttpHeaders headers = new HttpHeaders();
            headers.set("User-Agent", "HomeStock-BarcodeScanner/1.0 (contact@homestock.app)");
            headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));
            HttpEntity<Void> entity = new HttpEntity<>(headers);

            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.GET, entity, String.class);
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                int status = root.path("status").asInt(0);
                if (status == 1 && root.has("product")) {
                    JsonNode pNode = root.get("product");
                    String name = pNode.path("product_name").asText(pNode.path("product_name_en").asText("Unknown Product"));
                    if (name.isBlank() || name.equalsIgnoreCase("Unknown Product")) {
                        return Optional.empty();
                    }
                    String brand = pNode.path("brands").asText(null);
                    String image = pNode.path("image_front_url").asText(pNode.path("image_url").asText(null));
                    String categories = pNode.path("categories").asText("General");
                    String firstCategory = categories.contains(",") ? categories.split(",")[0].trim() : categories;

                    return Optional.of(ProductDto.builder()
                            .barcode(barcode)
                            .barcodeType(barcode.length() == 13 ? "EAN_13" : "UPC_A")
                            .name(name)
                            .normalizedName(name.toLowerCase().replaceAll("[^a-z0-9\\s]", " ").replaceAll("\\s+", " ").trim())
                            .brand(brand)
                            .categoryName(firstCategory)
                            .packageSize(BigDecimal.ONE)
                            .unit("pcs")
                            .imageUrl(image)
                            .source("OPEN_FOOD_FACTS")
                            .build());
                }
            }
        } catch (Exception e) {
            log.warn("OpenFoodFacts product lookup failed for barcode {}: {}", barcode, e.getMessage());
        }

        return Optional.empty();
    }

    @Override
    public List<ProductDto> searchByName(String query) {
        // Open Food Facts barcode lookup is primary; search by name is deferred to internal catalog
        return Collections.emptyList();
    }
}
