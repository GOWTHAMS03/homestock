package com.homestock.modules.smartshopping.engine.intent;

import com.homestock.modules.smartshopping.dto.ProductIntent;
import com.homestock.modules.smartshopping.dto.SearchIntent;
import com.homestock.modules.smartshopping.provider.ProductSearchRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Generates prioritized search queries across search engines.
 * Strictly respects exact vs generic rules:
 * - Exact searches retain brand and variant identity.
 * - Generic searches never introduce brands unrequested by the user.
 */
@Component
public class SearchQueryBuilder {

    private static final Logger log = LoggerFactory.getLogger(SearchQueryBuilder.class);

    /**
     * Build structured search requests for the providers according to intent.
     */
    public List<ProductSearchRequest> buildSearchQueries(ProductIntent intent, int maxResults) {
        List<ProductSearchRequest> requests = new ArrayList<>();
        Set<String> queryStrings = new LinkedHashSet<>();

        // 1. Barcode Search (highest priority)
        if (intent.getBarcode() != null && !intent.getBarcode().isBlank()) {
            requests.add(ProductSearchRequest.builder()
                    .barcode(intent.getBarcode())
                    .itemName(intent.getBarcode())
                    .brand(intent.getBrand())
                    .quantity(intent.getQuantity())
                    .unit(intent.getUnit())
                    .category(intent.getCategory())
                    .maxResults(maxResults)
                    .build());
            return requests;
        }

        SearchIntent searchIntent = intent.getSearchIntent();

        if (searchIntent == SearchIntent.EXACT_PRODUCT || searchIntent == SearchIntent.BRANDED_PRODUCT) {
            // Build exact prioritized queries
            String brand = intent.getBrand();
            String variant = intent.getVariant();
            String packSize = intent.getPackSize();
            String exactName = intent.getExactProductName();
            String genericName = intent.getGenericName();

            // Query 1: [brand] [exact product name] [variant] [pack size]
            StringBuilder q1 = new StringBuilder();
            if (brand != null) q1.append(brand).append(" ");
            if (variant != null) q1.append(variant).append(" ");
            if (genericName != null && !genericName.equalsIgnoreCase(variant)) q1.append(genericName).append(" ");
            if (packSize != null) q1.append(packSize);
            addQuery(queryStrings, q1.toString());

            // Query 2: [exact product name] [brand] [pack size]
            if (exactName != null) {
                StringBuilder q2 = new StringBuilder(exactName);
                if (packSize != null && !exactName.contains(packSize)) q2.append(" ").append(packSize);
                addQuery(queryStrings, q2.toString());
            }

            // Query 3: [brand] [product name] [variant]
            if (brand != null && variant != null) {
                addQuery(queryStrings, brand + " " + variant);
            }

            // Query 4: [brand] [product name]
            if (brand != null && genericName != null) {
                addQuery(queryStrings, brand + " " + genericName);
            }

            // Fallback query if raw product name differs
            if (intent.getProductName() != null) {
                addQuery(queryStrings, intent.getProductName());
            }
        } else if (searchIntent == SearchIntent.GENERIC_PRODUCT || searchIntent == SearchIntent.SPECIFIC_VARIANT) {
            // Generic product: NEVER add brand
            String genericName = intent.getGenericName() != null ? intent.getGenericName() : intent.getProductName();
            String category = intent.getCategory();
            String packSize = intent.getPackSize();

            // Query 1: [generic product name]
            if (genericName != null) {
                addQuery(queryStrings, genericName);
            }

            // Query 2: [generic product name] [category]
            if (genericName != null && category != null && !category.equalsIgnoreCase(genericName)) {
                addQuery(queryStrings, genericName + " " + category);
            }

            // Query 3: [generic product name] [pack size]
            if (genericName != null && packSize != null) {
                addQuery(queryStrings, genericName + " " + packSize);
            }

            // Also fallback to raw query
            if (intent.getRawInput() != null) {
                addQuery(queryStrings, intent.getRawInput());
            }
        } else {
            // INSUFFICIENT_INFORMATION: search cautiously
            if (intent.getRawInput() != null) {
                addQuery(queryStrings, intent.getRawInput());
            }
        }

        // Convert unique strings to ProductSearchRequest
        for (String q : queryStrings) {
            requests.add(ProductSearchRequest.builder()
                    .itemName(q)
                    .brand(intent.getBrand())
                    .barcode(intent.getBarcode())
                    .quantity(intent.getQuantity())
                    .unit(intent.getUnit())
                    .category(intent.getCategory())
                    .maxResults(maxResults)
                    .build());
        }

        log.debug("[SearchQueryBuilder] Generated {} search queries for intent '{}'", requests.size(), intent.getRawInput());
        return requests;
    }

    private void addQuery(Set<String> set, String query) {
        if (query != null) {
            String clean = query.replaceAll("\\s+", " ").trim();
            if (!clean.isBlank()) {
                set.add(clean);
            }
        }
    }
}
