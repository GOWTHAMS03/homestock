package com.homestock.modules.smartshopping.engine;

import com.homestock.modules.smartshopping.dto.ProductOfferDto;
import com.homestock.modules.smartshopping.dto.ProductSearchIntentDto;
import com.homestock.modules.smartshopping.provider.ProductSearchRequest;
import com.homestock.modules.smartshopping.provider.ShoppingProvider;
import com.homestock.modules.smartshopping.provider.ShoppingProviderRegistry;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.concurrent.*;

/**
 * ProductSearchEngine:
 * Coordinates search across shopping providers (Real Market, Local, Mock, etc.).
 * - In GENERIC_DISCOVERY mode: runs broader searches across category keywords and subtypes.
 * - In EXACT_PRODUCT mode: runs targeted exact product queries or barcode lookups.
 * - Collects and deduplicates raw offers across all active providers.
 */
@Component
@RequiredArgsConstructor
public class ProductSearchEngine {

    private static final Logger log = LoggerFactory.getLogger(ProductSearchEngine.class);

    private final ShoppingProviderRegistry providerRegistry;

    /**
     * Search all enabled providers based on structured intent.
     */
    public List<ProductOfferDto> searchProviders(ProductSearchIntentDto intent, int maxResultsPerProvider) {
        List<ShoppingProvider> enabledProviders = providerRegistry.getEnabledProviders();
        if (enabledProviders.isEmpty()) {
            log.warn("[ProductSearchEngine] No enabled shopping providers found");
            return Collections.emptyList();
        }

        List<ProductSearchRequest> searchQueries = buildSearchRequests(intent, maxResultsPerProvider);
        log.info("[ProductSearchEngine] Executing {} search queries across {} providers",
                searchQueries.size(), enabledProviders.size());

        List<ProductOfferDto> allOffers = new ArrayList<>();
        Set<String> seenOfferKeys = new HashSet<>();

        for (ShoppingProvider provider : enabledProviders) {
            // 0% Mock Guarantee: never query mock or demo providers
            if ("MOCK".equalsIgnoreCase(provider.getProviderName()) ||
                    provider.getProviderName().toUpperCase().contains("MOCK") ||
                    provider.getProviderName().toUpperCase().contains("DEMO")) {
                log.debug("[ProductSearchEngine] Skipping mock provider '{}'", provider.getProviderName());
                continue;
            }

            for (ProductSearchRequest request : searchQueries) {
                try {
                    List<ProductOfferDto> offers = provider.searchProducts(request);
                    for (ProductOfferDto offer : offers) {
                        String uniqueKey = offer.getProvider() + ":" + offer.getProviderProductId();
                        if (seenOfferKeys.add(uniqueKey)) {
                            allOffers.add(offer);
                        }
                    }
                } catch (Exception e) {
                    log.error("[ProductSearchEngine] Error querying provider '{}': {}", provider.getProviderName(), e.getMessage());
                }
            }
        }

        log.info("[ProductSearchEngine] Retrieved {} distinct product offers across providers", allOffers.size());
        return allOffers;
    }

    private List<ProductSearchRequest> buildSearchRequests(ProductSearchIntentDto intent, int maxResults) {
        List<ProductSearchRequest> requests = new ArrayList<>();

        if ("EXACT_PRODUCT".equalsIgnoreCase(intent.getSearchMode())) {
            // Exact mode: direct query
            ProductSearchRequest.ProductSearchRequestBuilder builder = ProductSearchRequest.builder()
                    .itemName(intent.getNormalizedQuery())
                    .brand(intent.getExtractedBrand())
                    .barcode(intent.getTargetBarcode())
                    .unit(intent.getExtractedUnit())
                    .maxResults(maxResults);

            requests.add(builder.build());

            if (intent.getExtractedBrand() != null && intent.getExtractedVariant() != null) {
                requests.add(ProductSearchRequest.builder()
                        .itemName(intent.getExtractedBrand() + " " + intent.getExtractedVariant())
                        .brand(intent.getExtractedBrand())
                        .maxResults(maxResults)
                        .build());
            }
        } else {
            // Generic discovery mode: query main category & top subtypes & popular market staples
            requests.add(ProductSearchRequest.builder()
                    .itemName(intent.getNormalizedQuery())
                    .maxResults(maxResults)
                    .build());

            // If intent has category like "Cooking Oil", also query with category name
            if (intent.getPrimaryCategory() != null && !intent.getPrimaryCategory().equalsIgnoreCase(intent.getNormalizedQuery())) {
                requests.add(ProductSearchRequest.builder()
                        .itemName(intent.getPrimaryCategory())
                        .maxResults(maxResults)
                        .build());
            }

            // Also search top 3 allowed subtypes to guarantee diverse discovery
            if (intent.getAllowedTypes() != null) {
                int count = 0;
                for (String subtype : intent.getAllowedTypes()) {
                    if (count++ >= 3) break;
                    String subQuery = subtype + " " + intent.getNormalizedQuery();
                    requests.add(ProductSearchRequest.builder()
                            .itemName(subQuery)
                            .maxResults(maxResults)
                            .build());
                }
            }

            // Query category-specific popular brand staples in India
            List<String> stapleQueries = getPopularStapleQueries(intent.getPrimaryCategory());
            for (String staple : stapleQueries) {
                requests.add(ProductSearchRequest.builder()
                        .itemName(staple)
                        .maxResults(maxResults)
                        .build());
            }
        }

        return requests;
    }

    private List<String> getPopularStapleQueries(String category) {
        if (category == null) return Collections.emptyList();
        switch (category) {
            case "Cooking Oil":
                return List.of("Fortune Sunflower Oil", "Saffola Gold Oil", "Dhara Mustard Oil");
            case "Rice & Grains":
                return List.of("India Gate Basmati Rice", "Daawat Basmati Rice", "Sona Masoori Rice");
            case "Atta & Flours":
                return List.of("Aashirvaad Atta", "Fortune Chakki Fresh Atta");
            case "Dals & Pulses":
                return List.of("Tata Sampann Toor Dal", "Tata Sampann Moong Dal");
            case "Dairy & Milk":
                return List.of("Amul Taaza Milk", "Amul Gold Milk");
            case "Tea & Coffee":
                return List.of("Tata Tea Gold", "Red Label Tea", "Bru Instant Coffee");
            case "Personal Care":
                return List.of("Dettol Soap", "Colgate Strong Teeth Toothpaste");
            case "Cleaning & Detergents":
                return List.of("Surf Excel Quick Wash", "Vim Dishwash Gel");
            default:
                return Collections.emptyList();
        }
    }
}
