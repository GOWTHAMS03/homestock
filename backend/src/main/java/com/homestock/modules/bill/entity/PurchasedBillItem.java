package com.homestock.modules.bill.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.product.entity.Product;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "purchased_bill_items")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchasedBillItem extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bill_id", nullable = false)
    private PurchasedBill bill;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id")
    private Product product;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inventory_item_id")
    private InventoryItem inventoryItem;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shopping_list_item_id")
    private ShoppingListItem shoppingListItem;

    @Column(name = "raw_item_name", nullable = false, length = 200)
    private String rawItemName;

    @Column(name = "normalized_item_name", length = 200)
    private String normalizedItemName;

    @Column(name = "quantity", nullable = false, precision = 12, scale = 3)
    private BigDecimal quantity;

    @Builder.Default
    @Column(name = "unit", nullable = false, length = 20)
    private String unit = "pcs";

    @Column(name = "mrp", precision = 10, scale = 2)
    private BigDecimal mrp;

    @Column(name = "unit_price", nullable = false, precision = 10, scale = 2)
    private BigDecimal unitPrice;

    @Builder.Default
    @Column(name = "discount", precision = 10, scale = 2)
    private BigDecimal discount = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "tax", precision = 10, scale = 2)
    private BigDecimal tax = BigDecimal.ZERO;

    @Column(name = "final_price", nullable = false, precision = 12, scale = 2)
    private BigDecimal finalPrice;

    @Column(name = "standard_unit_price", precision = 10, scale = 2)
    private BigDecimal standardUnitPrice;

    @Builder.Default
    @Column(name = "match_confidence", precision = 5, scale = 2)
    private BigDecimal matchConfidence = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "match_status", nullable = false, length = 30)
    private String matchStatus = "NEW_PRODUCT"; // AUTO_MATCHED, SUGGESTED, NEW_PRODUCT, MANUALLY_OVERRIDDEN
}
