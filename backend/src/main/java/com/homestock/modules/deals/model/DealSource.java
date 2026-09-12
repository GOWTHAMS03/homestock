package com.homestock.modules.deals.model;

/**
 * Supported shopping providers and marketplace deal sources.
 */
public enum DealSource {
    AMAZON("Amazon India", "https://www.amazon.in"),
    FLIPKART("Flipkart", "https://www.flipkart.com"),
    ONLINE_LIVE("Live Online", "https://www.google.com/shopping"),
    BLINKIT("Blinkit", "https://blinkit.com"),
    BIGBASKET("BigBasket", "https://www.bigbasket.com"),
    JIO_MART("JioMart", "https://www.jiomart.com"),
    ZEPTO("Zepto", "https://www.zepto.com"),
    LOCAL_STORE("Local Store", ""),
    OTHER("Other Store", "");

    private final String displayName;
    private final String baseUrl;

    DealSource(String displayName, String baseUrl) {
        this.displayName = displayName;
        this.baseUrl = baseUrl;
    }

    public String getDisplayName() {
        return displayName;
    }

    public String getBaseUrl() {
        return baseUrl;
    }

    public static DealSource fromString(String source) {
        if (source == null || source.isBlank()) {
            return OTHER;
        }
        String upper = source.trim().toUpperCase();
        for (DealSource s : values()) {
            if (s.name().equalsIgnoreCase(upper) || s.displayName.equalsIgnoreCase(upper)) {
                return s;
            }
        }
        if (upper.contains("AMAZON")) return AMAZON;
        if (upper.contains("FLIPKART")) return FLIPKART;
        if (upper.contains("BLINKIT")) return BLINKIT;
        if (upper.contains("BIGBASKET")) return BIGBASKET;
        if (upper.contains("JIOMART") || upper.contains("JIO_MART")) return JIO_MART;
        if (upper.contains("ZEPTO")) return ZEPTO;
        if (upper.contains("LOCAL")) return LOCAL_STORE;
        return OTHER;
    }
}
