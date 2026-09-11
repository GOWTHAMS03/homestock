package com.homestock.modules.smartshopping.engine.url;

import com.homestock.modules.smartshopping.dto.ProductCandidate;
import com.homestock.modules.smartshopping.dto.ProductIdentity;
import com.homestock.modules.smartshopping.dto.ProductUrlType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Default implementation of ProductUrlResolver.
 * Handles product URL resolution, redirect canonicalization, and identity consistency verification.
 * Conforms to Sections 42, 43, 44, 45, 46, 47, 51, 55, 56.
 */
@Component
public class DefaultProductUrlResolver implements ProductUrlResolver {

    private static final Logger log = LoggerFactory.getLogger(DefaultProductUrlResolver.class);

    private final ProductUrlValidator validator;

    public DefaultProductUrlResolver(ProductUrlValidator validator) {
        this.validator = validator;
    }

    @Override
    public String resolveProductUrl(ProductCandidate candidate) {
        if (candidate == null) return null;

        String rawUrl = candidate.getProductUrl();
        ProductUrlType type = validator.classifyUrl(rawUrl);

        // If candidate already has a valid PRODUCT_DETAIL_PAGE
        if (type == ProductUrlType.PRODUCT_DETAIL_PAGE) {
            String canonical = validator.canonicalizeUrl(rawUrl);
            candidate.setCanonicalProductUrl(canonical);
            candidate.setUrlType(ProductUrlType.PRODUCT_DETAIL_PAGE);
            candidate.setUrlVerified(true);
            candidate.setDirectProductUrlAvailable(true);
            return canonical;
        }

        // Store discovery URL as sourceUrl and do NOT use it as canonicalProductUrl
        candidate.setSourceUrl(rawUrl);

        // Attempt resolution to a direct product detail page
        String resolvedUrl = attemptDirectResolution(candidate);
        if (resolvedUrl != null) {
            ProductUrlType resType = validator.classifyUrl(resolvedUrl);
            if (resType == ProductUrlType.PRODUCT_DETAIL_PAGE) {
                String canonical = validator.canonicalizeUrl(resolvedUrl);
                candidate.setCanonicalProductUrl(canonical);
                candidate.setUrlType(ProductUrlType.PRODUCT_DETAIL_PAGE);
                candidate.setUrlVerified(true);
                candidate.setDirectProductUrlAvailable(true);
                return canonical;
            }
        }

        // Resolution failed: Section 51 Invalid URL Fallback
        log.debug("[ProductUrlResolver] Could not resolve direct product URL for candidate '{}' ({})",
                candidate.getProductName(), candidate.getProvider());
        candidate.setCanonicalProductUrl(null);
        candidate.setUrlType(type != null ? type : ProductUrlType.INVALID_URL);
        candidate.setUrlVerified(false);
        candidate.setDirectProductUrlAvailable(false);
        candidate.setUrlConfidence(0.0);

        return null;
    }

    private String attemptDirectResolution(ProductCandidate candidate) {
        String provider = candidate.getProvider() != null ? candidate.getProvider().toUpperCase() : "";
        String pid = candidate.getProviderProductId();

        // 1. Amazon: check for 10-character ASIN
        if (candidate.getAsin() != null && !candidate.getAsin().isBlank()) {
            return "https://www.amazon.in/dp/" + candidate.getAsin().trim();
        }
        if (provider.contains("AMAZON") && pid != null) {
            String cleanPid = pid.replace("AMZ-", "").trim();
            if (cleanPid.matches("[A-Z0-9]{10}")) {
                candidate.setAsin(cleanPid);
                return "https://www.amazon.in/dp/" + cleanPid;
            }
        }

        // 2. Flipkart: check for product ID
        if (provider.contains("FLIPKART") && pid != null && !pid.isBlank()) {
            String cleanPid = pid.replace("FLIP-", "").trim();
            return "https://www.flipkart.com/product/p/" + cleanPid;
        }

        // 3. Blinkit: check for item prid
        if (provider.contains("BLINKIT") && pid != null) {
            String cleanPid = pid.replace("BLK-", "").replace("BLINKIT-", "").trim();
            if (cleanPid.matches("[0-9a-zA-Z]+")) {
                String slug = toSlug(candidate.getProductName());
                return "https://blinkit.com/prn/" + slug + "/prid/" + cleanPid;
            }
        }

        // 4. BigBasket: check for item pd id
        if (provider.contains("BIGBASKET") && pid != null) {
            String cleanPid = pid.replace("BB-", "").trim();
            if (cleanPid.matches("[0-9]+")) {
                String slug = toSlug(candidate.getProductName());
                return "https://www.bigbasket.com/pd/" + cleanPid + "/" + slug + "/";
            }
        }

        // 5. JioMart: check for item id
        if (provider.contains("JIOMART") && pid != null) {
            String cleanPid = pid.replace("JIO-", "").replace("JIOMART-", "").trim();
            if (cleanPid.matches("[0-9a-zA-Z]+")) {
                String slug = toSlug(candidate.getProductName());
                return "https://www.jiomart.com/p/groceries/" + slug + "/" + cleanPid;
            }
        }

        // 6. Zepto: check for pvid
        if (provider.contains("ZEPTO") && pid != null) {
            String cleanPid = pid.replace("ZEPTO-", "").trim();
            if (cleanPid.matches("[0-9a-zA-Z-]+")) {
                String slug = toSlug(candidate.getProductName());
                return "https://www.zeptonow.com/pn/" + slug + "/pvid/" + cleanPid;
            }
        }

        return null;
    }

    private String toSlug(String text) {
        if (text == null || text.isBlank()) return "product";
        return text.toLowerCase()
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("^-+|-+$", "");
    }

    @Override
    public ProductUrlValidationResult validateProductUrl(String url) {
        return validator.validateProductUrl(url, null);
    }

    @Override
    public ProductUrlValidationResult validateProductUrl(String url, ProductIdentity identity) {
        return validator.validateProductUrl(url, identity);
    }

    @Override
    public ProductUrlMetadata extractProductMetadata(String url) {
        return validator.extractProductMetadata(url);
    }

    @Override
    public String canonicalizeUrl(String url) {
        return validator.canonicalizeUrl(url);
    }
}
