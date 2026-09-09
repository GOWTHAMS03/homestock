package com.homestock.modules.product.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductDto {
    private UUID id;
    private String barcode;
    private String barcodeType;
    private String name;
    private String normalizedName;
    private String brand;
    private UUID categoryId;
    private String categoryName;
    private BigDecimal packageSize;
    private String unit;
    private String packageUnit;
    private String description;
    private String imageUrl;
    private String source;
}
