package com.homestock.modules.smartshopping.engine.filter;

import com.homestock.modules.smartshopping.dto.*;
import com.homestock.modules.smartshopping.engine.identity.BrandResolver;
import com.homestock.modules.smartshopping.engine.identity.ProductAttributeExtractor;
import com.homestock.modules.smartshopping.engine.identity.ProductTaxonomy;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Hard Constraint Filter:
 * Evaluates candidate products against resolved ProductIdentity and hard IdentityConstraints.
 * Enforces "Product Correctness First, Price Second".
 * Rejects candidates BEFORE scoring or ranking with explicit RejectionReason.
 */
@Component
@RequiredArgsConstructor
public class HardConstraintFilter {

    private static final Logger log = LoggerFactory.getLogger(HardConstraintFilter.class);

    private final BrandResolver brandResolver;
    private final ProductAttributeExtractor attributeExtractor;
    private final ProductTaxonomy productTaxonomy;

    public record FilterResult(boolean passed, RejectedCandidate rejection) {
        public static FilterResult accept() {
            return new FilterResult(true, null);
        }
        public static FilterResult reject(ProductCandidate candidate, RejectionReason reason, String details) {
            return new FilterResult(false, RejectedCandidate.builder()
                    .candidateTitle(candidate.getProductName())
                    .provider(candidate.getProvider())
                    .rejectionReason(reason)
                    .details(details)
                    .build());
        }
    }

    /**
     * Filters a single candidate against the canonical ProductIdentity.
     */
    public FilterResult evaluate(ProductIdentity identity, ProductCandidate candidate) {
        if (candidate == null) {
            return FilterResult.reject(new ProductCandidate(), RejectionReason.UNAVAILABLE, "Null candidate");
        }

        // 0. Zero Mock Guarantee & Basic Sanity
        String provider = candidate.getProvider() != null ? candidate.getProvider().toUpperCase() : "";
        if (provider.contains("MOCK") || provider.contains("DEMO")) {
            return FilterResult.reject(candidate, RejectionReason.LOW_CONFIDENCE, "Mock provider rejected under Zero-Mock policy");
        }

        if (candidate.getPrice() == null || candidate.getPrice().compareTo(java.math.BigDecimal.ZERO) <= 0) {
            return FilterResult.reject(candidate, RejectionReason.PRICE_UNVERIFIED, "Candidate has invalid or zero price");
        }

        IdentityConstraints constraints = identity.getConstraints();
        if (constraints == null) {
            return FilterResult.accept();
        }

        String candTitle = candidate.getProductName() != null ? candidate.getProductName().trim() : "";
        String candBrand = candidate.getBrand() != null ? candidate.getBrand().trim() : "";

        // Extract attributes from candidate title to verify candidate ground truth
        ProductAttributeExtractor.ExtractedAttributes candAttrs = attributeExtractor.extract(candTitle, candidate.getBarcode());

        // 1. Hard Barcode Constraint
        if (constraints.isBarcodeRequired() && identity.getBarcode() != null) {
            String reqBarcode = identity.getBarcode().trim();
            String candBarcode = candidate.getBarcode() != null ? candidate.getBarcode().trim() : candAttrs.getBarcode();
            if (candBarcode != null && !candBarcode.equalsIgnoreCase(reqBarcode)) {
                return FilterResult.reject(candidate, RejectionReason.BARCODE_MISMATCH,
                        "Barcode mismatch: required " + reqBarcode + ", found " + candBarcode);
            }
        }

        // 2. Hard Brand Constraint
        if (constraints.isBrandRequired() && identity.getBrand() != null) {
            String reqBrand = identity.getBrand().trim();

            // Check if candidate explicitly lists a conflicting brand
            if (!candBrand.isBlank() && brandResolver.areConflictingBrands(reqBrand, candBrand)) {
                return FilterResult.reject(candidate, RejectionReason.WRONG_BRAND,
                        "Brand conflict: required '" + reqBrand + "', candidate explicitly belongs to '" + candBrand + "'");
            }

            // Check if candidate extracted brand conflicts
            if (candAttrs.getBrand() != null && brandResolver.areConflictingBrands(reqBrand, candAttrs.getBrand())) {
                return FilterResult.reject(candidate, RejectionReason.WRONG_BRAND,
                        "Brand conflict: required '" + reqBrand + "', candidate title mentions '" + candAttrs.getBrand() + "'");
            }

            // Candidate must contain the requested brand (or aliases) in brand or title
            boolean containsBrand = brandResolver.containsBrand(candBrand, reqBrand) ||
                                    brandResolver.containsBrand(candTitle, reqBrand);
            if (!containsBrand) {
                return FilterResult.reject(candidate, RejectionReason.WRONG_BRAND,
                        "Missing brand: candidate title '" + candTitle + "' does not contain required brand '" + reqBrand + "'");
            }
        }

        // 3. Hard Category Constraint & Negative Keywords
        if (constraints.isCategoryRequired() && identity.getCategory() != null) {
            boolean isClash = productTaxonomy.isCategoryClash(identity.getCategory(), candTitle);
            if (isClash) {
                return FilterResult.reject(candidate, RejectionReason.WRONG_CATEGORY,
                        "Category clash: candidate '" + candTitle + "' conflicts with required category '" + identity.getCategory() + "'");
            }
        }

        // 4. Hard Variant Constraint & Mutually Exclusive Clash
        if (constraints.isVariantRequired() && identity.getVariant() != null) {
            String reqVariant = identity.getVariant().trim();

            // Mutually exclusive clash check
            if (productTaxonomy.isVariantClash(reqVariant, candTitle)) {
                return FilterResult.reject(candidate, RejectionReason.WRONG_VARIANT,
                        "Mutually exclusive variant clash: required '" + reqVariant + "', candidate title contains conflicting variant");
            }

            // In EXACT mode, candidate must have the variant
            if (identity.getSearchMode() == SearchIntent.EXACT_PRODUCT) {
                String reqVarNorm = reqVariant.toLowerCase();
                String candTitleNorm = candTitle.toLowerCase();
                if (!candTitleNorm.contains(reqVarNorm)) {
                    return FilterResult.reject(candidate, RejectionReason.WRONG_VARIANT,
                            "Missing exact variant: required '" + reqVariant + "' not found in candidate title");
                }
            }
        }

        // 5. Hard Pack Size Constraint (Exact Mode)
        if (constraints.isPackSizeRequired() && identity.getNormalizedPackSizeValue() != null) {
            Double reqNormVal = identity.getNormalizedPackSizeValue().doubleValue();
            String reqNormUnit = identity.getNormalizedPackSizeUnit();

            // Candidate pack size from attribute extractor
            Double candNormVal = candAttrs.getNormalizedPackSizeValue();
            String candNormUnit = candAttrs.getNormalizedPackSizeUnit();

            if (candNormVal != null && candNormUnit != null && reqNormUnit != null) {
                if (!candNormUnit.equalsIgnoreCase(reqNormUnit)) {
                    return FilterResult.reject(candidate, RejectionReason.WRONG_PACK_SIZE,
                            "Pack unit mismatch: required " + reqNormUnit + ", candidate has " + candNormUnit);
                }

                double tolerance = constraints.getPackSizeTolerance() > 0 ? constraints.getPackSizeTolerance() : 0.05;
                double diffRatio = Math.abs(candNormVal - reqNormVal) / reqNormVal;
                if (diffRatio > tolerance) {
                    return FilterResult.reject(candidate, RejectionReason.WRONG_PACK_SIZE,
                            "Pack size out of tolerance: required " + reqNormVal + " " + reqNormUnit +
                            ", found " + candNormVal + " " + candNormUnit + " (diff " + String.format("%.1f", diffRatio * 100) + "%)");
                }
            }
        }

        return FilterResult.accept();
    }
}
