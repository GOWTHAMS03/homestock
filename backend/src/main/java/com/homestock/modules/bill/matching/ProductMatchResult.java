package com.homestock.modules.bill.matching;

import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.product.entity.Product;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductMatchResult {
    private BigDecimal confidence; // 0.00 to 100.00
    private String matchStatus;     // AUTO_MATCHED, SUGGESTED, NEW_PRODUCT
    private InventoryItem matchedInventoryItem;
    private Product matchedProduct;
    private ShoppingListItem matchedShoppingListItem;
    private String resolvedName;
    private String resolvedBrand;
    private String resolvedCategory;
    private String resolvedUnit;
    private BigDecimal resolvedQuantity;
    private BigDecimal resolvedUnitPrice;
    private BigDecimal resolvedFinalPrice;
    private BigDecimal standardUnitPrice;
}
