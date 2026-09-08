package com.homestock.modules.smartshopping.entity;

import com.homestock.core.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Common names, regional synonyms, and brand aliases for a canonical product.
 */
@Entity
@Table(name = "product_aliases", indexes = {
        @Index(name = "idx_pa_alias_name", columnList = "alias_name"),
        @Index(name = "idx_pa_product_id", columnList = "product_id")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductAlias extends BaseEntity {

    @Column(name = "product_id", nullable = false)
    private UUID productId;

    @Column(name = "alias_name", nullable = false, length = 200)
    private String aliasName;

    @Builder.Default
    @Column(name = "confidence", nullable = false, precision = 3, scale = 2)
    private BigDecimal confidence = BigDecimal.ONE;
}
