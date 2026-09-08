package com.homestock.modules.smartshopping.entity;

import com.homestock.core.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * An individual item considered or purchased within a shopping session.
 */
@Entity
@Table(name = "shopping_session_items", indexes = {
        @Index(name = "idx_ssi_session", columnList = "session_id")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShoppingSessionItem extends BaseEntity {

    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Column(name = "shopping_list_item_id")
    private UUID shoppingListItemId;

    @Column(name = "product_id")
    private UUID productId;

    @Column(name = "item_name", nullable = false, length = 200)
    private String itemName;

    @Column(name = "selected_provider", length = 50)
    private String selectedProvider;

    @Column(name = "provider_product_id", length = 200)
    private String providerProductId;

    @Builder.Default
    @Column(name = "quantity", nullable = false, precision = 12, scale = 3)
    private BigDecimal quantity = BigDecimal.ONE;

    @Builder.Default
    @Column(name = "unit", nullable = false, length = 20)
    private String unit = "pcs";

    @Column(name = "estimated_unit_price", precision = 12, scale = 2)
    private BigDecimal estimatedUnitPrice;

    @Column(name = "estimated_total_price", precision = 12, scale = 2)
    private BigDecimal estimatedTotalPrice;

    @Column(name = "actual_price", precision = 12, scale = 2)
    private BigDecimal actualPrice;

    @Builder.Default
    @Column(name = "is_purchased", nullable = false)
    private boolean isPurchased = false;

    @Column(name = "match_score", precision = 5, scale = 4)
    private BigDecimal matchScore;
}
