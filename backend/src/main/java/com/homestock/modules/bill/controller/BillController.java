package com.homestock.modules.bill.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.core.common.PagedResponse;
import com.homestock.core.util.PaginationUtils;
import com.homestock.core.util.SecurityUtils;
import com.homestock.modules.bill.dto.*;
import com.homestock.modules.bill.service.BillConfirmationService;
import com.homestock.modules.bill.service.BillScanService;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/homes/{homeId}/bills")
@Tag(name = "Bill Scanner", description = "Smart Purchased Bill Scanning, Extraction, and Confirmation")
public class BillController {

    private final BillScanService billScanService;
    private final BillConfirmationService billConfirmationService;
    private final UserRepository userRepository;

    public BillController(
            BillScanService billScanService,
            BillConfirmationService billConfirmationService,
            UserRepository userRepository
    ) {
        this.billScanService = billScanService;
        this.billConfirmationService = billConfirmationService;
        this.userRepository = userRepository;
    }

    @PostMapping(value = "/scan", consumes = {MediaType.MULTIPART_FORM_DATA_VALUE, MediaType.APPLICATION_JSON_VALUE})
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Scan receipt image or text, extract items, detect duplicates, and preview matching")
    public ResponseEntity<ApiResponse<BillScanPreviewResponseDto>> scanBill(
            @PathVariable UUID homeId,
            @RequestParam(value = "files", required = false) List<MultipartFile> files,
            @RequestParam(value = "rawText", required = false) String rawText,
            @RequestBody(required = false) RawTextScanRequest bodyRequest
    ) {
        User currentUser = getCurrentUser();
        String text = rawText != null ? rawText : (bodyRequest != null ? bodyRequest.getRawText() : null);

        BillScanPreviewResponseDto preview = billScanService.scanBill(homeId, files, text, currentUser);
        return ResponseEntity.ok(ApiResponse.success(preview));
    }

    @PostMapping("/{billId}/confirm")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Confirm scanned bill, atomically update inventory, shopping list, purchase history & price history")
    public ResponseEntity<ApiResponse<BillResponseDto>> confirmBill(
            @PathVariable UUID homeId,
            @PathVariable UUID billId,
            @Valid @RequestBody ConfirmBillRequest request
    ) {
        User currentUser = getCurrentUser();
        BillResponseDto confirmed = billConfirmationService.confirmBill(homeId, billId, request, currentUser);
        return ResponseEntity.ok(ApiResponse.success(confirmed));
    }

    @GetMapping("/{billId}")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Get single bill details and line items")
    public ResponseEntity<ApiResponse<BillResponseDto>> getBill(
            @PathVariable UUID homeId,
            @PathVariable UUID billId
    ) {
        BillResponseDto bill = billScanService.getBillById(homeId, billId);
        return ResponseEntity.ok(ApiResponse.success(bill));
    }

    @GetMapping
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "List scanned and confirmed household bills")
    public ResponseEntity<ApiResponse<PagedResponse<BillResponseDto>>> getBills(
            @PathVariable UUID homeId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        Pageable pageable = PageRequest.of(PaginationUtils.clampPage(page), PaginationUtils.clampSize(size));
        PagedResponse<BillResponseDto> bills = billScanService.getBills(homeId, pageable);
        return ResponseEntity.ok(ApiResponse.success(bills));
    }

    private User getCurrentUser() {
        try {
            UUID userId = SecurityUtils.getCurrentUserId();
            return userRepository.findById(userId).orElse(null);
        } catch (Exception e) {
            return null;
        }
    }

    public static class RawTextScanRequest {
        private String rawText;
        public String getRawText() { return rawText; }
        public void setRawText(String rawText) { this.rawText = rawText; }
    }
}
