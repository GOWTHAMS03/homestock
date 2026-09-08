package com.homestock.modules.smartshopping.entity;

import com.homestock.core.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

/**
 * Standard identifier for a product (e.g. GTIN, EAN, ASIN, FSN, Barcode).
 */
@Entity
@Table(name = "product_identifiers", indexes = {
        @Index(name = "idx_pi_type_val", columnList = "identifier_type, identifier_value"),
        @Index(name = "idx_pi_product_id", columnList = "product_id")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductIdentifier extends BaseEntity {

    @Column(name = "product_id", nullable = false)
    private UUID productId;

    @Column(name = "identifier_type", nullable = false, length = 30)
    private String identifierType; // GTIN, ASIN, FSN, BARCODE, SKU

    @Column(name = "identifier_value", nullable = false, length = 100)
    private String identifierValue;
}
