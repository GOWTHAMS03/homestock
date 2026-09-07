package com.homestock.modules.smartshopping;

import com.homestock.modules.smartshopping.provider.ProductSearchRequest;
import com.homestock.modules.smartshopping.provider.mock.MockProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

class MockProviderTest {

    private MockProvider mockProvider;

    @BeforeEach
    void setUp() {
        mockProvider = new MockProvider();
        ReflectionTestUtils.setField(mockProvider, "enabled", true);
    }

    @Test
    @DisplayName("MockProvider should search and find milk offers")
    void searchMilk() {
        var request = ProductSearchRequest.builder()
                .itemName("Milk")
                .quantity(new BigDecimal("1"))
                .unit("L")
                .build();

        var offers = mockProvider.searchProducts(request);
        assertThat(offers).isNotEmpty();
        assertThat(offers).anyMatch(o -> o.getProductName().toLowerCase().contains("milk"));
    }

    @Test
    @DisplayName("MockProvider should build affiliate URL correctly")
    void buildAffiliateUrl() {
        String url = mockProvider.buildAffiliateUrl("MOCK-001", "https://example.com/product/1");
        assertThat(url).contains("ref=homestock_mock");
        assertThat(url).contains("pid=MOCK-001");
    }

    @Test
    @DisplayName("MockProvider returns empty when disabled")
    void disabledProviderReturnsEmpty() {
        ReflectionTestUtils.setField(mockProvider, "enabled", false);
        var request = ProductSearchRequest.builder()
                .itemName("Milk")
                .build();

        var offers = mockProvider.searchProducts(request);
        assertThat(offers).isEmpty();
    }
}
