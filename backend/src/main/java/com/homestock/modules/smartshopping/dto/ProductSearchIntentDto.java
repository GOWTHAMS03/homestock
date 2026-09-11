package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductSearchIntentDto {
    private String rawQuery;
    private String normalizedQuery;
    private String searchMode; // "GENERIC_DISCOVERY" or "EXACT_PRODUCT"
    private String searchPriority; // "BARCODE", "EXACT_PRODUCT_NAME", "BRAND_AND_TYPE", "TYPE_AND_VARIANT", "GENERIC_CATEGORY"
    private String primaryCategory;
    private String extractedVariant;
    private String extractedBrand;
    private String extractedPackSize;
    private String extractedUnit;
    private String targetBarcode;
    private List<String> allowedTypes;
}
