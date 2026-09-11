package com.homestock.modules.smartshopping.engine.identity;

import com.homestock.modules.smartshopping.dto.IdentityConstraints;
import com.homestock.modules.smartshopping.dto.ProductIdentity;
import com.homestock.modules.smartshopping.dto.SearchIntent;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

/**
 * Product Identity Resolver:
 * Creates a canonical ProductIdentity object from raw text and optional barcode.
 * Resolves search mode (EXACT_PRODUCT, BRANDED_PRODUCT, CATEGORY_SEARCH, GENERIC_SEARCH)
 * and defines hard IdentityConstraints to enforce across candidate retrieval and filtering.
 */
@Component
@RequiredArgsConstructor
public class ProductIdentityResolver {

    private static final Logger log = LoggerFactory.getLogger(ProductIdentityResolver.class);

    private final ProductAttributeExtractor attributeExtractor;

    /**
     * Resolves the user query into a canonical ProductIdentity.
     */
    public ProductIdentity resolve(String query, String barcode) {
        if (query == null) query = "";
        String cleanQuery = query.trim();

        // 1. Extract structured attributes
        ProductAttributeExtractor.ExtractedAttributes attrs = attributeExtractor.extract(cleanQuery, barcode);

        // 2. Classify Search Mode & Intent
        SearchIntent searchMode = determineSearchMode(attrs);

        // 3. Build Hard Identity Constraints based on Search Mode & Extracted Data
        IdentityConstraints constraints = buildConstraints(searchMode, attrs);

        BigDecimal normVal = attrs.getNormalizedPackSizeValue() != null ? BigDecimal.valueOf(attrs.getNormalizedPackSizeValue()) : null;
        BigDecimal reqQty = attrs.getRequestedQuantity() != null ? BigDecimal.valueOf(attrs.getRequestedQuantity()) : BigDecimal.ONE;

        // 4. Assemble canonical ProductIdentity
        ProductIdentity identity = ProductIdentity.builder()
                .brand(attrs.getBrand())
                .product(attrs.getProductName())
                .genericName(attrs.getGenericName())
                .variant(attrs.getVariant())
                .packSize(normVal)
                .packUnit(attrs.getPackUnit())
                .normalizedPackSizeValue(normVal)
                .normalizedPackSizeUnit(attrs.getNormalizedPackSizeUnit())
                .requestedQuantity(reqQty)
                .requestedQuantityUnit(attrs.getRequestedQuantityUnit())
                .category(attrs.getCategory())
                .subCategory(attrs.getSubCategory())
                .productType(attrs.getGenericName() != null ? attrs.getGenericName() : attrs.getProductName())
                .searchMode(searchMode)
                .constraints(constraints)
                .barcode(attrs.getBarcode())
                .confidence(attrs.getExtractionConfidence())
                .build();

        log.info("Resolved ProductIdentity: brand='{}', product='{}', variant='{}', packSize='{}' ({} {}), mode='{}', confidence={}",
                identity.getBrand(), identity.getProduct(), identity.getVariant(),
                identity.getPackSize(), identity.getNormalizedPackSizeValue(), identity.getNormalizedPackSizeUnit(),
                identity.getSearchMode(), identity.getConfidence());

        return identity;
    }

    private SearchIntent determineSearchMode(ProductAttributeExtractor.ExtractedAttributes attrs) {
        if (attrs.getBarcode() != null && !attrs.getBarcode().isBlank()) {
            return SearchIntent.BARCODE_SEARCH;
        }

        boolean hasBrand = attrs.getBrand() != null;
        boolean hasVariant = attrs.getVariant() != null;
        boolean hasPackSize = attrs.getPackSize() != null;

        if (hasBrand && hasPackSize) {
            return SearchIntent.EXACT_PRODUCT;
        } else if (hasBrand) {
            return SearchIntent.BRANDED_PRODUCT;
        } else if (hasVariant || (attrs.getCategory() != null && !attrs.getCategory().equalsIgnoreCase("General Grocery"))) {
            return SearchIntent.CATEGORY_SEARCH;
        } else {
            return SearchIntent.GENERIC_SEARCH;
        }
    }

    private IdentityConstraints buildConstraints(SearchIntent mode, ProductAttributeExtractor.ExtractedAttributes attrs) {
        return switch (mode) {
            case BARCODE_SEARCH -> IdentityConstraints.builder()
                    .barcodeRequired(true)
                    .brandRequired(attrs.getBrand() != null)
                    .categoryRequired(true)
                    .packSizeTolerance(0.0)
                    .build();

            case EXACT_PRODUCT -> IdentityConstraints.builder()
                    .brandRequired(attrs.getBrand() != null)
                    .productRequired(true)
                    .variantRequired(attrs.getVariant() != null)
                    .packSizeRequired(attrs.getPackSize() != null)
                    .categoryRequired(attrs.getCategory() != null)
                    .packSizeTolerance(0.05) // within 5% tolerance
                    .build();

            case BRANDED_PRODUCT -> IdentityConstraints.builder()
                    .brandRequired(true)
                    .productRequired(true)
                    .variantRequired(attrs.getVariant() != null)
                    .packSizeRequired(false)
                    .categoryRequired(attrs.getCategory() != null)
                    .packSizeTolerance(0.10)
                    .build();

            case CATEGORY_SEARCH, GENERIC_SEARCH -> IdentityConstraints.builder()
                    .brandRequired(false)
                    .productRequired(true)
                    .variantRequired(attrs.getVariant() != null)
                    .packSizeRequired(false)
                    .categoryRequired(true)
                    .packSizeTolerance(0.20)
                    .build();

            default -> IdentityConstraints.builder().build();
        };
    }
}
