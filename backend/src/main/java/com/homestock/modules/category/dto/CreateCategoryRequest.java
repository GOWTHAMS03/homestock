package com.homestock.modules.category.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreateCategoryRequest {
    @NotBlank(message = "Category name is required")
    @Size(min = 1, max = 80)
    private String name;

    private String icon = "category";
    private String colorHex = "#6366F1";
    private Integer displayOrder = 0;
}
