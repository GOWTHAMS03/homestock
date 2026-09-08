package com.homestock.modules.smartshopping.provider.mock;

import com.homestock.modules.smartshopping.dto.ProductOfferDto;
import com.homestock.modules.smartshopping.provider.ProductSearchRequest;
import com.homestock.modules.smartshopping.provider.ProviderCapability;
import com.homestock.modules.smartshopping.provider.ShoppingProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Mock shopping provider for development and testing.
 * <p>
 * Returns realistic Indian grocery product data without making external API calls.
 * This provider is enabled by default in development and should be disabled in production.
 */
@Component
public class MockProvider implements ShoppingProvider {

    private static final Logger log = LoggerFactory.getLogger(MockProvider.class);

    @Value("${app.smart-shopping.providers.mock.enabled:true}")
    private boolean enabled;

    private static final List<MockProduct> CATALOG = buildCatalog();

    @Override
    public String getProviderName() {
        return "MOCK";
    }

    @Override
    public String getDisplayName() {
        return "HomeStock Store (Demo)";
    }

    @Override
    public boolean isEnabled() {
        return enabled;
    }

    @Override
    public Set<ProviderCapability> getCapabilities() {
        return Set.of(
                ProviderCapability.SEARCH,
                ProviderCapability.PRODUCT_DETAILS,
                ProviderCapability.OFFERS,
                ProviderCapability.PRICE,
                ProviderCapability.AVAILABILITY,
                ProviderCapability.DEEP_LINK,
                ProviderCapability.AFFILIATE_LINK
        );
    }

    @Override
    public List<ProductOfferDto> searchProducts(ProductSearchRequest request) {
        if (!enabled) return Collections.emptyList();

        log.debug("[MockProvider] Searching for: {}", request.getItemName());

        String query = request.getItemName().toLowerCase().trim();
        String brandFilter = request.getBrand() != null ? request.getBrand().toLowerCase().trim() : null;

        return CATALOG.stream()
                .filter(p -> {
                    String name = p.name.toLowerCase();
                    String brand = p.brand.toLowerCase();
                    // Match if query contains product keywords or brand
                    return name.contains(query) || query.contains(name)
                            || brand.contains(query) || query.contains(brand)
                            || Arrays.stream(query.split("\\s+"))
                                    .anyMatch(word -> name.contains(word) || brand.contains(word));
                })
                .filter(p -> brandFilter == null || p.brand.toLowerCase().contains(brandFilter))
                .limit(request.getMaxResults())
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Override
    public Optional<ProductOfferDto> getProduct(String providerProductId) {
        if (!enabled) return Optional.empty();

        return CATALOG.stream()
                .filter(p -> p.id.equals(providerProductId))
                .findFirst()
                .map(this::toDto);
    }

    @Override
    public String buildAffiliateUrl(String providerProductId, String originalUrl) {
        // Mock affiliate URL — in reality would append tracking tags
        return originalUrl + "?ref=homestock_mock&pid=" + providerProductId;
    }

    private ProductOfferDto toDto(MockProduct p) {
        BigDecimal effectivePrice = p.price.add(p.deliveryCharge);
        return ProductOfferDto.builder()
                .provider(getProviderName())
                .providerProductId(p.id)
                .productName(p.name)
                .brand(p.brand)
                .description(p.description)
                .imageUrl(null) // No images for mock
                .productUrl("https://example.com/products/" + p.id)
                .affiliateUrl(buildAffiliateUrl(p.id, "https://example.com/products/" + p.id))
                .price(p.price)
                .currency("INR")
                .deliveryCharge(p.deliveryCharge)
                .effectivePrice(effectivePrice)
                .availability(p.availability)
                .estimatedDelivery(p.estimatedDelivery)
                .packageSize(p.packageSize)
                .unit(p.unit)
                .rating(p.rating)
                .reviewCount(p.reviewCount)
                .lastCheckedAt(Instant.now())
                .build();
    }

    // ──── Mock Catalog ────

    private static List<MockProduct> buildCatalog() {
        List<MockProduct> products = new ArrayList<>();

        // Rice
        products.add(new MockProduct("MOCK-001", "India Gate Basmati Rice", "India Gate", "Premium aged basmati rice, extra long grain",
                new BigDecimal("599"), BigDecimal.ZERO, "5 kg", "kg", "IN_STOCK", "Tomorrow", new BigDecimal("4.4"), 12340));
        products.add(new MockProduct("MOCK-002", "Daawat Rozana Basmati Rice", "Daawat", "Everyday basmati rice for daily cooking",
                new BigDecimal("435"), BigDecimal.ZERO, "5 kg", "kg", "IN_STOCK", "Tomorrow", new BigDecimal("4.2"), 8920));
        products.add(new MockProduct("MOCK-003", "Fortune Everyday Basmati Rice", "Fortune", "Full grain basmati rice",
                new BigDecimal("389"), new BigDecimal("40"), "5 kg", "kg", "IN_STOCK", "2 days", new BigDecimal("4.1"), 5670));

        // Cooking Oil
        products.add(new MockProduct("MOCK-010", "Fortune Sunflower Refined Oil", "Fortune", "Light and healthy refined sunflower oil",
                new BigDecimal("145"), BigDecimal.ZERO, "1 L", "L", "IN_STOCK", "Tomorrow", new BigDecimal("4.3"), 9800));
        products.add(new MockProduct("MOCK-011", "Saffola Gold Cooking Oil", "Saffola", "Blended edible vegetable oil for healthy cooking",
                new BigDecimal("179"), BigDecimal.ZERO, "1 L", "L", "IN_STOCK", "Tomorrow", new BigDecimal("4.5"), 15200));
        products.add(new MockProduct("MOCK-012", "Fortune Sunflower Refined Oil", "Fortune", "Light and healthy refined sunflower oil — 5L pack",
                new BigDecimal("620"), BigDecimal.ZERO, "5 L", "L", "IN_STOCK", "2 days", new BigDecimal("4.3"), 7400));

        // Sugar
        products.add(new MockProduct("MOCK-020", "Trust Classic Sulphurless Sugar", "Trust", "Pure sulphurless refined sugar",
                new BigDecimal("52"), BigDecimal.ZERO, "1 kg", "kg", "IN_STOCK", "Tomorrow", new BigDecimal("4.2"), 3400));
        products.add(new MockProduct("MOCK-021", "Madhur Pure Sugar", "Madhur", "Pure white crystal sugar",
                new BigDecimal("48"), new BigDecimal("20"), "1 kg", "kg", "IN_STOCK", "2 days", new BigDecimal("4.0"), 2100));

        // Atta / Flour
        products.add(new MockProduct("MOCK-030", "Aashirvaad Superior MP Atta", "Aashirvaad", "100% whole wheat atta, soft rotis every time",
                new BigDecimal("289"), BigDecimal.ZERO, "5 kg", "kg", "IN_STOCK", "Tomorrow", new BigDecimal("4.5"), 28900));
        products.add(new MockProduct("MOCK-031", "Aashirvaad Multigrain Atta", "Aashirvaad", "6 grains for added nutrition",
                new BigDecimal("329"), BigDecimal.ZERO, "5 kg", "kg", "IN_STOCK", "Tomorrow", new BigDecimal("4.4"), 12400));
        products.add(new MockProduct("MOCK-032", "Pillsbury Chakki Fresh Atta", "Pillsbury", "Fresh chakki atta for soft rotis",
                new BigDecimal("275"), new BigDecimal("30"), "5 kg", "kg", "IN_STOCK", "2 days", new BigDecimal("4.1"), 6700));

        // Dal / Lentils
        products.add(new MockProduct("MOCK-040", "Tata Sampann Toor Dal", "Tata Sampann", "Unpolished toor dal with natural oils",
                new BigDecimal("159"), BigDecimal.ZERO, "1 kg", "kg", "IN_STOCK", "Tomorrow", new BigDecimal("4.3"), 7800));
        products.add(new MockProduct("MOCK-041", "24 Mantra Organic Tur Dal", "24 Mantra", "100% certified organic toor dal",
                new BigDecimal("225"), BigDecimal.ZERO, "1 kg", "kg", "IN_STOCK", "2 days", new BigDecimal("4.6"), 3200));

        // Salt
        products.add(new MockProduct("MOCK-050", "Tata Salt", "Tata", "Vacuum evaporated iodised salt",
                new BigDecimal("25"), BigDecimal.ZERO, "1 kg", "kg", "IN_STOCK", "Tomorrow", new BigDecimal("4.4"), 45600));

        // Toothpaste
        products.add(new MockProduct("MOCK-060", "Colgate Strong Teeth Toothpaste", "Colgate", "Amino Shakti formula with calcium boost",
                new BigDecimal("105"), BigDecimal.ZERO, "300 g", "g", "IN_STOCK", "Tomorrow", new BigDecimal("4.3"), 18700));
        products.add(new MockProduct("MOCK-061", "Pepsodent Germicheck Toothpaste", "Pepsodent", "12 hour germ protection",
                new BigDecimal("95"), BigDecimal.ZERO, "300 g", "g", "IN_STOCK", "Tomorrow", new BigDecimal("4.1"), 8900));

        // Milk
        products.add(new MockProduct("MOCK-070", "Amul Taaza Homogenised Toned Milk", "Amul", "Fresh toned milk, 1L tetra pack",
                new BigDecimal("68"), BigDecimal.ZERO, "1 L", "L", "IN_STOCK", "Today", new BigDecimal("4.2"), 11200));

        // Detergent
        products.add(new MockProduct("MOCK-080", "Surf Excel Easy Wash Detergent Powder", "Surf Excel", "Dissolves easily in water for quick wash",
                new BigDecimal("245"), BigDecimal.ZERO, "1.5 kg", "kg", "IN_STOCK", "Tomorrow", new BigDecimal("4.4"), 22100));
        products.add(new MockProduct("MOCK-081", "Ariel Matic Top Load Detergent", "Ariel", "Superior stain removal in top load machines",
                new BigDecimal("399"), BigDecimal.ZERO, "2 kg", "kg", "IN_STOCK", "Tomorrow", new BigDecimal("4.5"), 16800));

        // Tea / Coffee
        products.add(new MockProduct("MOCK-090", "Tata Tea Premium", "Tata Tea", "Desh ki chai — rich, strong taste",
                new BigDecimal("340"), BigDecimal.ZERO, "500 g", "g", "IN_STOCK", "Tomorrow", new BigDecimal("4.3"), 19400));
        products.add(new MockProduct("MOCK-091", "Nescafé Classic Instant Coffee", "Nescafé", "100% pure soluble coffee",
                new BigDecimal("460"), BigDecimal.ZERO, "200 g", "g", "IN_STOCK", "Tomorrow", new BigDecimal("4.4"), 25300));

        return Collections.unmodifiableList(products);
    }

    private static class MockProduct {
        final String id;
        final String name;
        final String brand;
        final String description;
        final BigDecimal price;
        final BigDecimal deliveryCharge;
        final String packageSize;
        final String unit;
        final String availability;
        final String estimatedDelivery;
        final BigDecimal rating;
        final int reviewCount;

        MockProduct(String id, String name, String brand, String description,
                    BigDecimal price, BigDecimal deliveryCharge, String packageSize, String unit,
                    String availability, String estimatedDelivery, BigDecimal rating, int reviewCount) {
            this.id = id;
            this.name = name;
            this.brand = brand;
            this.description = description;
            this.price = price;
            this.deliveryCharge = deliveryCharge;
            this.packageSize = packageSize;
            this.unit = unit;
            this.availability = availability;
            this.estimatedDelivery = estimatedDelivery;
            this.rating = rating;
            this.reviewCount = reviewCount;
        }
    }
}
