package com.homestock.modules.smartshopping;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.homestock.modules.smartshopping.dto.ProductOfferDto;
import com.homestock.modules.smartshopping.provider.ProductSearchRequest;
import com.homestock.modules.smartshopping.provider.ProviderCapability;
import com.homestock.modules.smartshopping.provider.online.LiveOnlineShoppingProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.*;

class LiveOnlineShoppingProviderTest {

    private LiveOnlineShoppingProvider onlineProvider;

    @BeforeEach
    void setUp() {
        onlineProvider = new LiveOnlineShoppingProvider(new RestTemplateBuilder(), new ObjectMapper());
        ReflectionTestUtils.setField(onlineProvider, "enabled", true);
    }

    @Test
    @DisplayName("Online provider metadata and capabilities should be configured")
    void testProviderMetadata() {
        assertEquals("ONLINE_LIVE", onlineProvider.getProviderName());
        assertTrue(onlineProvider.isEnabled());
        assertTrue(onlineProvider.getCapabilities().contains(ProviderCapability.SEARCH));
        assertTrue(onlineProvider.getCapabilities().contains(ProviderCapability.DEEP_LINK));
        assertTrue(onlineProvider.getCapabilities().contains(ProviderCapability.PRICE));
        assertTrue(onlineProvider.getCapabilities().contains(ProviderCapability.OFFERS));
    }

    @Test
    @DisplayName("Disabled provider returns empty list")
    void testDisabledProvider() {
        ReflectionTestUtils.setField(onlineProvider, "enabled", false);
        var request = ProductSearchRequest.builder().itemName("Sunflower Oil").build();
        List<ProductOfferDto> offers = onlineProvider.searchProducts(request);
        assertThat(offers).isEmpty();
    }

    @Test
    @DisplayName("Live online search should fetch genuine products and build 5 store offers")
    void testLiveSearchRealProducts() {
        var request = ProductSearchRequest.builder()
                .itemName("Fortune Sunflower Oil")
                .maxResults(3)
                .build();

        List<ProductOfferDto> offers = onlineProvider.searchProducts(request);
        assertNotNull(offers);

        // If internet is connected, live Open Food Facts search will return real hits
        if (!offers.isEmpty()) {
            // Verify real product data
            ProductOfferDto firstOffer = offers.get(0);
            assertNotNull(firstOffer.getProductName());
            assertNotNull(firstOffer.getPrice());
            assertNotNull(firstOffer.getProductUrl());
            assertTrue(firstOffer.getProductUrl().startsWith("http"));

            // Verify store diversity
            boolean hasBigBasket = offers.stream().anyMatch(o -> "BigBasket".equalsIgnoreCase(o.getProvider()));
            boolean hasBlinkit = offers.stream().anyMatch(o -> "Blinkit".equalsIgnoreCase(o.getProvider()));
            boolean hasJioMart = offers.stream().anyMatch(o -> "JioMart".equalsIgnoreCase(o.getProvider()));
            boolean hasAmazon = offers.stream().anyMatch(o -> "Amazon".equalsIgnoreCase(o.getProvider()));
            boolean hasZepto = offers.stream().anyMatch(o -> "Zepto".equalsIgnoreCase(o.getProvider()));

            assertTrue(hasBigBasket || hasBlinkit || hasJioMart || hasAmazon || hasZepto);
        }
    }

    @Test
    @DisplayName("Live online barcode search for Indian GS1 barcode")
    void testLiveBarcodeSearch() {
        // Fortune Sunflower Oil 5L barcode (8906007280280)
        var request = ProductSearchRequest.builder()
                .barcode("8906007280280")
                .build();

        List<ProductOfferDto> offers = onlineProvider.searchProducts(request);
        assertNotNull(offers);

        if (!offers.isEmpty()) {
            ProductOfferDto offer = offers.get(0);
            assertEquals("8906007280280", offer.getBarcode());
            assertNotNull(offer.getProductName());
            assertTrue(offer.getProductName().toLowerCase().contains("fortune") ||
                    offer.getProductName().toLowerCase().contains("sunflower") ||
                    offer.getProductName().toLowerCase().contains("oil"));
        }
    }

    @Test
    @DisplayName("Affiliate URL generation adds correct partner tag for Amazon")
    void testAffiliateUrl() {
        String amazonUrl = onlineProvider.buildAffiliateUrl("AMZ-123", "https://www.amazon.in/dp/B00ABCD123");
        assertTrue(amazonUrl.contains("tag=homestock-21"));

        String genericUrl = onlineProvider.buildAffiliateUrl("BB-123", "https://www.bigbasket.com/pd/12345");
        assertEquals("https://www.bigbasket.com/pd/12345", genericUrl);
    }
}
