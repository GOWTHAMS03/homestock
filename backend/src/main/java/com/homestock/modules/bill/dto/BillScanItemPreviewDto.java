package com.homestock.modules.bill.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BillScanItemPreviewDto {
    private String rawItemName;
    private String matchedProductName;
    private String categoryName;
    private UUID matchedProductId;
    private UUID matchedInventoryItemId;
    private BigDecimal quantity;
    private String unit;
    private BigDecimal mrp;
    private BigDecimal unitPrice;
    private BigDecimal discount;
    private BigDecimal tax;
    private BigDecimal finalPrice;
    private BigDecimal standardUnitPrice;
    private BigDecimal matchConfidence;
    private String matchStatus; // AUTO_MATCHED, SUGGESTED, NEW_PRODUCT
    private UUID matchedShoppingListItemId;
    private String matchedShoppingItemName;
    private List<ExistingProductMatchDto> suggestedMatches;

    // AI Pipeline confidence fields
    private BigDecimal nameConfidence;
    private BigDecimal quantityConfidence;
    private BigDecimal priceConfidence;
    private boolean needsReview;
    private String reviewReason;

    public String getMatchedExistingProductName() {
        return matchedProductName;
    }

    public String getNormalizedItemName() {
        return matchedProductName;
    }
}
