package com.homestock.modules.category.service;

import com.homestock.core.exception.BusinessRuleException;
import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.category.dto.CategoryDto;
import com.homestock.modules.category.dto.CreateCategoryRequest;
import com.homestock.modules.category.entity.Category;
import com.homestock.modules.category.repository.CategoryRepository;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository categoryRepository;
    private final HomeRepository homeRepository;

    @Transactional(readOnly = true)
    public List<CategoryDto> getCategoriesForHome(UUID homeId) {
        return categoryRepository.findAllByHomeIdOrGlobal(homeId).stream()
                .map(CategoryDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public CategoryDto createCategory(UUID homeId, CreateCategoryRequest request) {
        Home home = homeRepository.findById(homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Home not found"));

        if (categoryRepository.existsByHomeIdAndNameIgnoreCase(homeId, request.getName().trim())) {
            throw new BusinessRuleException("Category with this name already exists in this home");
        }

        Category category = Category.builder()
                .home(home)
                .name(request.getName().trim())
                .icon(request.getIcon() != null ? request.getIcon() : "category")
                .colorHex(request.getColorHex() != null ? request.getColorHex() : "#6366F1")
                .displayOrder(request.getDisplayOrder() != null ? request.getDisplayOrder() : 0)
                .build();

        return CategoryDto.fromEntity(categoryRepository.save(category));
    }

    @Transactional
    public void seedDefaultCategoriesForHome(Home home) {
        record DefaultCategory(String name, String icon, String color, int order) {}
        List<DefaultCategory> defaults = List.of(
                new DefaultCategory("Kitchen", "restaurant", "#F59E0B", 1),
                new DefaultCategory("Cleaning", "cleaning_services", "#3B82F6", 2),
                new DefaultCategory("Bathroom", "bathtub", "#10B981", 3),
                new DefaultCategory("Personal Care", "face", "#EC4899", 4),
                new DefaultCategory("Pantry & Snacks", "fastfood", "#8B5CF6", 5),
                new DefaultCategory("Others", "inventory_2", "#6B7280", 6)
        );

        for (DefaultCategory def : defaults) {
            Category category = Category.builder()
                    .home(home)
                    .name(def.name())
                    .icon(def.icon())
                    .colorHex(def.color())
                    .displayOrder(def.order())
                    .build();
            categoryRepository.save(category);
        }
    }
}
