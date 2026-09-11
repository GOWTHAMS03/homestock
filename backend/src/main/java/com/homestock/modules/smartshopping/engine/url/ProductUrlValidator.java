package com.homestock.modules.smartshopping.engine.url;

import com.homestock.modules.smartshopping.dto.ProductIdentity;
import com.homestock.modules.smartshopping.dto.ProductUrlType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Validates, canonicalizes, and verifies product URLs.
 * Conforms to Sections 43, 44, 45, 47, 55.
 */
@Component
public class ProductUrlValidator {

    private static final Logger log = LoggerFactory.getLogger(ProductUrlValidator.class);

    // Tracking / advertising parameters to strip during canonicalization
    private static final Set<String> TRACKING_PARAMS = Set.of(
            "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
            "tag", "affid", "ref", "ref_", "spm", "gclid", "fbclid",
            "session-id", "qid", "sr", "pf_rd_r", "pf_rd_p", "ascsubtag",
            "dchild", "keywords", "crid", "sprefix"
    );

    // Retailer-specific product detail regex patterns
    private static final Pattern AMAZON_DP_PATTERN = Pattern.compile(".*/(?:dp|gp/product)/([A-Z0-9]{10})(?:[/?].*)?$");
    private static final Pattern FLIPKART_P_PATTERN = Pattern.compile(".*/([a-zA-Z0-9-]+)/p/([a-zA-Z0-9]+)(?:[/?].*)?$");
    private static final Pattern FLIPKART_ALT_P_PATTERN = Pattern.compile(".*/product/p/([a-zA-Z0-9]+)(?:[/?].*)?$");
    private static final Pattern BLINKIT_PRN_PATTERN = Pattern.compile(".*/prn/([a-zA-Z0-9-]+)/prid/([0-9a-zA-Z]+)(?:[/?].*)?$");
    private static final Pattern BIGBASKET_PD_PATTERN = Pattern.compile(".*/pd/([0-9]+)(?:/([a-zA-Z0-9-]+)/?)?(?:[/?].*)?$");
    private static final Pattern JIOMART_P_PATTERN = Pattern.compile(".*/p/[a-zA-Z0-9-]+/([a-zA-Z0-9-]+)/([0-9a-zA-Z]+)(?:[/?].*)?$");
    private static final Pattern ZEPTO_PN_PATTERN = Pattern.compile(".*/pn/([a-zA-Z0-9-]+)/pvid/([a-zA-Z0-9-]+)(?:[/?].*)?$");

    // Generic search patterns
    private static final List<String> SEARCH_KEYWORDS = List.of(
            "/search", "/s?", "/s/?", "/s/", "/ps/?", "/ps/", "?q=", "&q=", "?k=", "&k=", "query=", "search_query="
    );

    // Known conflicting oil variants for slug mismatch detection
    private static final Set<String> OIL_VARIANTS = Set.of(
            "sunflower", "groundnut", "peanut", "mustard", "coconut", "sesame", "gingelly",
            "rice bran", "ricebran", "olive", "soyabean", "soya", "palmolein", "canola"
    );

    // Known conflicting brands
    private static final Set<String> KNOWN_BRANDS = Set.of(
            "fortune", "dhara", "saffola", "gemini", "emami", "freedom", "gold winner", "sunpure",
            "tata sampann", "aashirvaad", "pillsbury", "daawat", "india gate", "kohinoor",
            "surf excel", "ariel", "tide", "vim", "colgate", "pepsodent", "dettol", "lifebuoy"
    );

    /**
     * Determines the ProductUrlType of a raw URL.
     */
    public ProductUrlType classifyUrl(String url) {
        if (url == null || url.isBlank()) {
            return ProductUrlType.INVALID_URL;
        }

        String trimmed = url.trim();
        if (!trimmed.startsWith("http://") && !trimmed.startsWith("https://")) {
            return ProductUrlType.INVALID_URL;
        }

        try {
            URI uri = URI.create(trimmed);
            String path = uri.getPath() != null ? uri.getPath().toLowerCase() : "";
            String query = uri.getQuery() != null ? uri.getQuery().toLowerCase() : "";
            String fullPathAndQuery = path + (query.isEmpty() ? "" : "?" + query);

            // 1. Homepage detection
            if (path.isEmpty() || path.equals("/") || path.equals("/index.html") || path.equals("/home")) {
                if (query.isEmpty() || (!query.contains("q=") && !query.contains("k="))) {
                    return ProductUrlType.HOMEPAGE;
                }
            }

            // 2. Search Page detection
            for (String kw : SEARCH_KEYWORDS) {
                if (fullPathAndQuery.contains(kw)) {
                    return ProductUrlType.SEARCH_PAGE;
                }
            }

            // 3. Category Page detection
            if (path.startsWith("/c/") || path.contains("/category/") || path.contains("/collections/") ||
                    path.contains("/browse/") || path.startsWith("/cn/") || path.startsWith("/cl/") ||
                    path.contains("/dept/")) {
                // Confirm it's not a product detail page matching one of the detail patterns
                if (!isRetailerDetailPath(trimmed)) {
                    return ProductUrlType.CATEGORY_PAGE;
                }
            }

            // 4. Product Detail Page detection
            if (isRetailerDetailPath(trimmed)) {
                return ProductUrlType.PRODUCT_DETAIL_PAGE;
            }

            // Generic product detail fallback (e.g. /product/..., /item/..., /p/...)
            if (path.contains("/product/") || path.contains("/products/") || path.contains("/item/") ||
                    path.matches(".*/p/[0-9a-zA-Z_-]+.*")) {
                return ProductUrlType.PRODUCT_DETAIL_PAGE;
            }

            // If it doesn't match a known product pattern, treat as CATEGORY or SEARCH
            if (path.split("/").length <= 2) {
                return ProductUrlType.HOMEPAGE;
            }

            return ProductUrlType.INVALID_URL;

        } catch (Exception e) {
            log.debug("[ProductUrlValidator] URL parse error for '{}': {}", url, e.getMessage());
            return ProductUrlType.INVALID_URL;
        }
    }

    private boolean isRetailerDetailPath(String url) {
        return AMAZON_DP_PATTERN.matcher(url).matches() ||
                FLIPKART_P_PATTERN.matcher(url).matches() ||
                FLIPKART_ALT_P_PATTERN.matcher(url).matches() ||
                BLINKIT_PRN_PATTERN.matcher(url).matches() ||
                BIGBASKET_PD_PATTERN.matcher(url).matches() ||
                JIOMART_P_PATTERN.matcher(url).matches() ||
                ZEPTO_PN_PATTERN.matcher(url).matches();
    }

    /**
     * Canonicalizes a URL by stripping tracking and session query parameters.
     * Conforms to Section 47 & Section 55.
     */
    public String canonicalizeUrl(String url) {
        if (url == null || url.isBlank()) return null;

        try {
            URI uri = URI.create(url.trim());
            String scheme = uri.getScheme() != null ? uri.getScheme() : "https";
            String host = uri.getHost();
            if (host == null) return url;

            String path = uri.getPath() != null ? uri.getPath() : "";

            // Normalize Amazon canonical URL to https://www.amazon.in/dp/{ASIN}
            Matcher amz = AMAZON_DP_PATTERN.matcher(url);
            if (amz.matches()) {
                String asin = amz.group(1);
                return "https://www.amazon.in/dp/" + asin;
            }

            // Normalize Blinkit canonical URL
            Matcher blk = BLINKIT_PRN_PATTERN.matcher(url);
            if (blk.matches()) {
                String slug = blk.group(1);
                String prid = blk.group(2);
                return "https://blinkit.com/prn/" + slug + "/prid/" + prid;
            }

            // Normalize BigBasket canonical URL
            Matcher bb = BIGBASKET_PD_PATTERN.matcher(url);
            if (bb.matches()) {
                String id = bb.group(1);
                String slug = bb.group(2) != null ? bb.group(2) : "product";
                return "https://www.bigbasket.com/pd/" + id + "/" + slug + "/";
            }

            // Normalize JioMart canonical URL
            Matcher jio = JIOMART_P_PATTERN.matcher(url);
            if (jio.matches()) {
                String slug = jio.group(1);
                String id = jio.group(2);
                return "https://www.jiomart.com/p/groceries/" + slug + "/" + id;
            }

            // Normalize Zepto canonical URL
            Matcher zepto = ZEPTO_PN_PATTERN.matcher(url);
            if (zepto.matches()) {
                String slug = zepto.group(1);
                String id = zepto.group(2);
                return "https://www.zeptonow.com/pn/" + slug + "/pvid/" + id;
            }

            // Normalize Flipkart canonical URL
            Matcher flip = FLIPKART_P_PATTERN.matcher(url);
            if (flip.matches()) {
                String slug = flip.group(1);
                String id = flip.group(2);
                return "https://www.flipkart.com/" + slug + "/p/" + id;
            }

            // Strip tracking query params
            String rawQuery = uri.getRawQuery();
            StringBuilder cleanQuery = new StringBuilder();
            if (rawQuery != null && !rawQuery.isBlank()) {
                String[] pairs = rawQuery.split("&");
                for (String pair : pairs) {
                    int idx = pair.indexOf("=");
                    String key = idx > 0 ? pair.substring(0, idx).toLowerCase() : pair.toLowerCase();
                    if (!TRACKING_PARAMS.contains(key)) {
                        if (cleanQuery.length() > 0) cleanQuery.append("&");
                        cleanQuery.append(pair);
                    }
                }
            }

            String result = scheme + "://" + host + path;
            if (cleanQuery.length() > 0) {
                result += "?" + cleanQuery.toString();
            }
            return result;

        } catch (Exception e) {
            log.debug("[ProductUrlValidator] Canonicalization error: {}", e.getMessage());
            return url;
        }
    }

    /**
     * Extracts structured product metadata from a URL.
     */
    public ProductUrlMetadata extractProductMetadata(String url) {
        ProductUrlType type = classifyUrl(url);
        String canonical = canonicalizeUrl(url);

        ProductUrlMetadata.ProductUrlMetadataBuilder builder = ProductUrlMetadata.builder()
                .rawUrl(url)
                .canonicalUrl(canonical)
                .urlType(type);

        if (url == null || url.isBlank()) {
            return builder.build();
        }

        try {
            URI uri = URI.create(url.trim());
            builder.domain(uri.getHost());

            // Amazon
            Matcher amz = AMAZON_DP_PATTERN.matcher(url);
            if (amz.matches()) {
                String asin = amz.group(1);
                builder.asin(asin).retailerProductId(asin);
                return builder.build();
            }

            // Flipkart
            Matcher flip = FLIPKART_P_PATTERN.matcher(url);
            if (flip.matches()) {
                builder.urlSlug(flip.group(1));
                builder.retailerProductId(flip.group(2));
                extractSlugAttributes(flip.group(1), builder);
                return builder.build();
            }

            // Blinkit
            Matcher blk = BLINKIT_PRN_PATTERN.matcher(url);
            if (blk.matches()) {
                builder.urlSlug(blk.group(1));
                builder.retailerProductId(blk.group(2));
                extractSlugAttributes(blk.group(1), builder);
                return builder.build();
            }

            // BigBasket
            Matcher bb = BIGBASKET_PD_PATTERN.matcher(url);
            if (bb.matches()) {
                builder.retailerProductId(bb.group(1));
                if (bb.group(2) != null) {
                    builder.urlSlug(bb.group(2));
                    extractSlugAttributes(bb.group(2), builder);
                }
                return builder.build();
            }

            // JioMart
            Matcher jio = JIOMART_P_PATTERN.matcher(url);
            if (jio.matches()) {
                builder.urlSlug(jio.group(1));
                builder.retailerProductId(jio.group(2));
                extractSlugAttributes(jio.group(1), builder);
                return builder.build();
            }

            // Zepto
            Matcher zepto = ZEPTO_PN_PATTERN.matcher(url);
            if (zepto.matches()) {
                builder.urlSlug(zepto.group(1));
                builder.retailerProductId(zepto.group(2));
                extractSlugAttributes(zepto.group(1), builder);
                return builder.build();
            }

        } catch (Exception e) {
            log.debug("[ProductUrlValidator] extractProductMetadata error: {}", e.getMessage());
        }

        return builder.build();
    }

    private void extractSlugAttributes(String slug, ProductUrlMetadata.ProductUrlMetadataBuilder builder) {
        if (slug == null) return;
        String normalized = slug.toLowerCase().replace("-", " ").replace("_", " ");

        // Extract brand from slug
        for (String brand : KNOWN_BRANDS) {
            if (normalized.contains(brand)) {
                builder.extractedBrand(brand);
                break;
            }
        }

        // Extract variant from slug
        for (String variant : OIL_VARIANTS) {
            if (normalized.contains(variant)) {
                builder.extractedVariant(variant);
                break;
            }
        }
    }

    /**
     * Validates URL and verifies consistency with ProductIdentity (Section 44 & 45).
     */
    public ProductUrlValidationResult validateProductUrl(String url, ProductIdentity identity) {
        if (url == null || url.isBlank()) {
            return ProductUrlValidationResult.invalid("Product URL is null or blank.");
        }

        ProductUrlType type = classifyUrl(url);

        if (type == ProductUrlType.SEARCH_PAGE) {
            return ProductUrlValidationResult.rejected(
                    ProductUrlType.SEARCH_PAGE,
                    "Rejected search-result page: " + url + ". Only direct product detail pages are permitted."
            );
        }

        if (type == ProductUrlType.CATEGORY_PAGE) {
            return ProductUrlValidationResult.rejected(
                    ProductUrlType.CATEGORY_PAGE,
                    "Rejected category browse page: " + url + ". Only direct product detail pages are permitted."
            );
        }

        if (type == ProductUrlType.HOMEPAGE) {
            return ProductUrlValidationResult.rejected(
                    ProductUrlType.HOMEPAGE,
                    "Rejected retailer homepage: " + url + ". Only direct product detail pages are permitted."
            );
        }

        if (type != ProductUrlType.PRODUCT_DETAIL_PAGE) {
            return ProductUrlValidationResult.rejected(
                    type,
                    "Rejected URL with type " + type + ": " + url + ". Direct product detail page required."
            );
        }

        // It is a PRODUCT_DETAIL_PAGE! Now perform Section 44: URL + Product Identity Consistency Check
        ProductUrlMetadata metadata = extractProductMetadata(url);
        String canonical = metadata.getCanonicalUrl() != null ? metadata.getCanonicalUrl() : canonicalizeUrl(url);

        // If identity is null, accept as verified product detail page with default confidence
        if (identity == null) {
            return ProductUrlValidationResult.builder()
                    .urlType(ProductUrlType.PRODUCT_DETAIL_PAGE)
                    .urlVerified(true)
                    .urlConfidence(0.90)
                    .canonicalProductUrl(canonical)
                    .validationMessage("Direct product detail page verified.")
                    .metadata(metadata)
                    .directProductUrlAvailable(true)
                    .build();
        }

        String slug = metadata.getUrlSlug() != null ? metadata.getUrlSlug().toLowerCase() : "";
        String fullUrlLower = url.toLowerCase();

        // 1. Check Brand Conflict (Section 44)
        if (identity.getBrand() != null && !identity.getBrand().isBlank()) {
            String idBrand = identity.getBrand().toLowerCase().trim();
            for (String otherBrand : KNOWN_BRANDS) {
                if (!otherBrand.equalsIgnoreCase(idBrand) && !idBrand.contains(otherBrand) && !otherBrand.contains(idBrand)) {
                    if (slug.contains(otherBrand) || (fullUrlLower.contains("/" + otherBrand) && !fullUrlLower.contains(idBrand))) {
                        log.warn("[ProductUrlValidator] Section 44 Brand Mismatch: identity brand '{}' vs URL brand '{}' in '{}'",
                                idBrand, otherBrand, url);
                        return ProductUrlValidationResult.builder()
                                .urlType(ProductUrlType.PRODUCT_DETAIL_PAGE)
                                .urlVerified(false)
                                .urlConfidence(0.0)
                                .canonicalProductUrl(canonical)
                                .validationMessage("Brand conflict detected: URL refers to '" + otherBrand + "' while requested brand is '" + idBrand + "'.")
                                .metadata(metadata)
                                .directProductUrlAvailable(false)
                                .build();
                    }
                }
            }
        }

        // 2. Check Variant Conflict (Section 44)
        // e.g. Fortune Sunflower Oil requested vs Fortune Groundnut Oil URL
        if (identity.getVariant() != null && !identity.getVariant().isBlank()) {
            String idVariant = identity.getVariant().toLowerCase().trim();
            for (String otherVariant : OIL_VARIANTS) {
                if (!otherVariant.equalsIgnoreCase(idVariant) && !idVariant.contains(otherVariant)) {
                    if (slug.contains(otherVariant) || fullUrlLower.contains(otherVariant)) {
                        log.warn("[ProductUrlValidator] Section 44 Variant Mismatch: identity variant '{}' vs URL variant '{}' in '{}'",
                                idVariant, otherVariant, url);
                        return ProductUrlValidationResult.builder()
                                .urlType(ProductUrlType.PRODUCT_DETAIL_PAGE)
                                .urlVerified(false)
                                .urlConfidence(0.0)
                                .canonicalProductUrl(canonical)
                                .validationMessage("Variant conflict detected: URL refers to '" + otherVariant + "' while requested variant is '" + idVariant + "'.")
                                .metadata(metadata)
                                .directProductUrlAvailable(false)
                                .build();
                    }
                }
            }
        }

        // 3. Compute Confidence based on positive signal matching
        double confidence = 0.90;
        if (metadata.getRetailerProductId() != null || metadata.getAsin() != null) {
            confidence += 0.05;
        }

        if (identity.getBrand() != null && slug.contains(identity.getBrand().toLowerCase())) {
            confidence += 0.03;
        }

        confidence = Math.min(1.0, confidence);

        return ProductUrlValidationResult.builder()
                .urlType(ProductUrlType.PRODUCT_DETAIL_PAGE)
                .urlVerified(true)
                .urlConfidence(confidence)
                .canonicalProductUrl(canonical)
                .validationMessage("Direct product detail page verified with matching product identity.")
                .metadata(metadata)
                .directProductUrlAvailable(true)
                .build();
    }
}
