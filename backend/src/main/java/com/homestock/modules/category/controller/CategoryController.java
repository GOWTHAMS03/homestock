package com.homestock.modules.category.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.category.dto.CategoryDto;
import com.homestock.modules.category.dto.CreateCategoryRequest;
import com.homestock.modules.category.service.CategoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/homes/{homeId}/categories")
@RequiredArgsConstructor
@Tag(name = "Categories", description = "Endpoints for managing home product categories")
public class CategoryController {

    private final CategoryService categoryService;

    @GetMapping
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get all categories for a home")
    public ResponseEntity<ApiResponse<List<CategoryDto>>> getCategories(@PathVariable UUID homeId) {
        List<CategoryDto> categories = categoryService.getCategoriesForHome(homeId);
        return ResponseEntity.ok(ApiResponse.success(categories));
    }

    @PostMapping
    @PreAuthorize("@homeSecurity.hasPermission(#homeId, T(com.homestock.modules.home.entity.HomeRole).ADMIN)")
    @Operation(summary = "Create custom category for a home")
    public ResponseEntity<ApiResponse<CategoryDto>> createCategory(
            @PathVariable UUID homeId,
            @Valid @RequestBody CreateCategoryRequest request) {
        CategoryDto created = categoryService.createCategory(homeId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Category created", created));
    }
}
