package com.homestock.modules.bill.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.bill.dto.CategoryExpenseDto;
import com.homestock.modules.bill.dto.MonthlyExpenseReportDto;
import com.homestock.modules.bill.dto.ProductPriceIntelligenceDto;
import com.homestock.modules.bill.dto.ShopExpenseDto;
import com.homestock.modules.bill.service.ExpenseIntelligenceService;
import com.homestock.modules.bill.service.PriceIntelligenceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/homes/{homeId}/analytics")
@Tag(name = "Expense Intelligence & Price Analytics", description = "Monthly expense reports, category spending, shop breakdowns, and product price trends")
public class ExpenseAnalyticsController {

    private final ExpenseIntelligenceService expenseIntelligenceService;
    private final PriceIntelligenceService priceIntelligenceService;

    public ExpenseAnalyticsController(
            ExpenseIntelligenceService expenseIntelligenceService,
            PriceIntelligenceService priceIntelligenceService
    ) {
        this.expenseIntelligenceService = expenseIntelligenceService;
        this.priceIntelligenceService = priceIntelligenceService;
    }

    @GetMapping("/monthly")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get current monthly spending report, trend vs previous month, and summary metrics")
    public ResponseEntity<ApiResponse<MonthlyExpenseReportDto>> getCurrentMonthlyReport(
            @PathVariable UUID homeId
    ) {
        LocalDate now = LocalDate.now();
        MonthlyExpenseReportDto report = expenseIntelligenceService.getMonthlyReport(homeId, now.getYear(), now.getMonthValue());
        return ResponseEntity.ok(ApiResponse.success(report));
    }

    @GetMapping("/monthly/{year}/{month}")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get historical monthly expense report for specified year and month")
    public ResponseEntity<ApiResponse<MonthlyExpenseReportDto>> getMonthlyReport(
            @PathVariable UUID homeId,
            @PathVariable int year,
            @PathVariable int month
    ) {
        MonthlyExpenseReportDto report = expenseIntelligenceService.getMonthlyReport(homeId, year, month);
        return ResponseEntity.ok(ApiResponse.success(report));
    }

    @GetMapping("/category")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get category-wise spending breakdown and percentages")
    public ResponseEntity<ApiResponse<List<CategoryExpenseDto>>> getCategoryBreakdown(
            @PathVariable UUID homeId,
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month
    ) {
        LocalDate now = LocalDate.now();
        int y = year != null ? year : now.getYear();
        int m = month != null ? month : now.getMonthValue();

        List<CategoryExpenseDto> list = expenseIntelligenceService.getCategoryBreakdown(homeId, y, m);
        return ResponseEntity.ok(ApiResponse.success(list));
    }

    @GetMapping("/shop")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get shop-wise spending breakdown and retailer visit counts")
    public ResponseEntity<ApiResponse<List<ShopExpenseDto>>> getShopBreakdown(
            @PathVariable UUID homeId,
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month
    ) {
        LocalDate now = LocalDate.now();
        int y = year != null ? year : now.getYear();
        int m = month != null ? month : now.getMonthValue();

        List<ShopExpenseDto> list = expenseIntelligenceService.getShopBreakdown(homeId, y, m);
        return ResponseEntity.ok(ApiResponse.success(list));
    }

    @GetMapping("/products/{productId}/price-history")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get product price intelligence, price per standard unit, and store comparison")
    public ResponseEntity<ApiResponse<ProductPriceIntelligenceDto>> getProductPriceHistory(
            @PathVariable UUID homeId,
            @PathVariable UUID productId
    ) {
        ProductPriceIntelligenceDto data = priceIntelligenceService.getProductPriceIntelligence(homeId, productId);
        return ResponseEntity.ok(ApiResponse.success(data));
    }

    @GetMapping("/inventory/{itemId}/price-history")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get inventory item price intelligence, price per standard unit, and store comparison")
    public ResponseEntity<ApiResponse<ProductPriceIntelligenceDto>> getItemPriceHistory(
            @PathVariable UUID homeId,
            @PathVariable UUID itemId
    ) {
        ProductPriceIntelligenceDto data = priceIntelligenceService.getInventoryItemPriceIntelligence(homeId, itemId);
        return ResponseEntity.ok(ApiResponse.success(data));
    }
}
