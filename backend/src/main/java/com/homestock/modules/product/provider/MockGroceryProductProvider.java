package com.homestock.modules.product.provider;

import com.homestock.modules.product.dto.ProductDto;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

@Component
public class MockGroceryProductProvider implements ProductDataProvider {

    private final Map<String, ProductDto> mockCatalog = new HashMap<>();

    public MockGroceryProductProvider() {
        seedProducts();
    }

    private void seedProducts() {
        addMock("8901030000003", "EAN_13", "Tata Salt Vacuum Evaporated Iodised Salt", "Tata", "Grocery", new BigDecimal("1.0"), "kg", "https://m.media-amazon.com/images/I/61t+OqR2vQL.jpg");
        addMock("8901725181222", "EAN_13", "Aashirvaad Superior MP Shudh Chakki Whole Wheat Atta", "Aashirvaad", "Grocery", new BigDecimal("5.0"), "kg", "https://m.media-amazon.com/images/I/71YyM34r8mL.jpg");
        addMock("8901262010053", "EAN_13", "Amul Taaza Homogenised Toned Milk", "Amul", "Dairy", new BigDecimal("1.0"), "L", "https://m.media-amazon.com/images/I/61Nl8q2V9nL.jpg");
        addMock("8906007280013", "EAN_13", "Fortune Sunlite Refined Sunflower Oil", "Fortune", "Cooking Essentials", new BigDecimal("1.0"), "L", "https://m.media-amazon.com/images/I/61Xq0z02l4L.jpg");
        addMock("8901058852890", "EAN_13", "Maggi 2-Minute Masala Instant Noodles", "Maggi", "Packaged Food", new BigDecimal("280.0"), "g", "https://m.media-amazon.com/images/I/81xU9d71QJL.jpg");
        addMock("8901030383707", "EAN_13", "Parle-G Original Gluco Biscuits", "Parle", "Snacks", new BigDecimal("800.0"), "g", "https://m.media-amazon.com/images/I/71Sg0q3nL4L.jpg");
        addMock("8901314010529", "EAN_13", "Colgate Strong Teeth Anticavity Toothpaste", "Colgate", "Personal Care", new BigDecimal("200.0"), "g", "https://m.media-amazon.com/images/I/61k1qfJ8MOL.jpg");
        addMock("8901396225217", "EAN_13", "Dettol Original Liquid Handwash Refill", "Dettol", "Hygiene", new BigDecimal("200.0"), "ml", "https://m.media-amazon.com/images/I/61UaXq44PBL.jpg");
        addMock("8901030825276", "EAN_13", "Surf Excel Quick Wash Detergent Powder", "Surf Excel", "Cleaning", new BigDecimal("1.0"), "kg", "https://m.media-amazon.com/images/I/71P4m-6c1XL.jpg");
        addMock("8901063012111", "EAN_13", "Britannia Good Day Butter Cookies", "Britannia", "Snacks", new BigDecimal("200.0"), "g", "https://m.media-amazon.com/images/I/71lU4Q9n-0L.jpg");
    }

    private void addMock(String barcode, String type, String name, String brand, String category, BigDecimal size, String unit, String image) {
        mockCatalog.put(barcode, ProductDto.builder()
                .barcode(barcode)
                .barcodeType(type)
                .name(name)
                .normalizedName(name.toLowerCase().replaceAll("[^a-z0-9\\s]", " ").replaceAll("\\s+", " ").trim())
                .brand(brand)
                .categoryName(category)
                .packageSize(size)
                .unit(unit)
                .imageUrl(image)
                .source("MOCK_GROCERY_CATALOG")
                .build());
    }

    @Override
    public String getProviderName() {
        return "MOCK_CATALOG";
    }

    @Override
    public int getPriority() {
        return 2;
    }

    @Override
    public Optional<ProductDto> findByBarcode(String barcode) {
        return Optional.ofNullable(mockCatalog.get(barcode));
    }

    @Override
    public List<ProductDto> searchByName(String query) {
        if (query == null || query.isBlank()) {
            return Collections.emptyList();
        }
        String q = query.toLowerCase();
        return mockCatalog.values().stream()
                .filter(p -> p.getName().toLowerCase().contains(q) || (p.getBrand() != null && p.getBrand().toLowerCase().contains(q)))
                .collect(Collectors.toList());
    }
}
