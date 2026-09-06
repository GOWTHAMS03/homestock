package com.homestock.modules.category.dto;

import com.homestock.modules.category.entity.Category;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CategoryDto {
    private UUID id;
    private UUID homeId;
    private String name;
    private String icon;
    private String colorHex;
    private Integer displayOrder;

    public static CategoryDto fromEntity(Category category) {
        if (category == null) return null;
        return CategoryDto.builder()
                .id(category.getId())
                .homeId(category.getHome() != null ? category.getHome().getId() : null)
                .name(category.getName())
                .icon(category.getIcon())
                .colorHex(category.getColorHex())
                .displayOrder(category.getDisplayOrder())
                .build();
    }
}
