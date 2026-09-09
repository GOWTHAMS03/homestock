package com.homestock.modules.product.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.category.entity.Category;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "products")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Product extends BaseEntity {

    @Column(name = "barcode", length = 50, unique = true)
    private String barcode;

    @Builder.Default
    @Column(name = "barcode_type", nullable = false, length = 30)
    private String barcodeType = "EAN_13";

    @Column(name = "name", nullable = false, length = 200)
    private String name;

    @Column(name = "normalized_name", nullable = false, length = 200)
    private String normalizedName;

    @Column(name = "brand", length = 100)
    private String brand;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    @Column(name = "category_name", length = 100)
    private String categoryName;

    @Column(name = "package_size", precision = 10, scale = 3)
    private BigDecimal packageSize;

    @Builder.Default
    @Column(name = "unit", nullable = false, length = 20)
    private String unit = "pcs";

    @Column(name = "image_url", length = 512)
    private String imageUrl;

    @Builder.Default
    @Column(name = "source", nullable = false, length = 50)
    private String source = "INTERNAL";

    @Column(name = "sub_category", length = 100)
    private String subCategory;

    @Column(name = "gtin", length = 50)
    private String gtin;

    @Column(name = "variant", length = 100)
    private String variant;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "package_unit", length = 30)
    private String packageUnit;

    @Builder.Default
    @OneToMany(mappedBy = "product", cascade = CascadeType.ALL, orphanRemoval = true)
    private java.util.List<ProductIdentifier> identifiers = new java.util.ArrayList<>();
}
