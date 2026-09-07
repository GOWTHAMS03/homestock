package com.homestock.modules.product.dto;

import jakarta.validation.constraints.NotBlank;
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
public class CreateProductRequest {

    private String barcode;
    private String barcodeType;

    @NotBlank(message = "Product name is required")
    private String name;

    private String brand;
    private UUID categoryId;
    private String categoryName;
    private BigDecimal packageSize;
    private String unit;
    private String imageUrl;
}
