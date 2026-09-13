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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/homes/{homeId}/bills")
@Tag(name = "Bill Scanner", description = "Smart Purchased Bill Scanning, Extraction, and Confirmation")
public class BillController {

    private static final Logger log = LoggerFactory.getLogger(BillController.class);

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

    @PostMapping(value = "/scan", consumes = MediaType.APPLICATION_JSON_VALUE)
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Scan receipt JSON payload (raw OCR text or base64 images), extract items, detect duplicates, and preview matching")
    public ResponseEntity<ApiResponse<BillScanPreviewResponseDto>> scanBillJson(
            @PathVariable UUID homeId,
            @RequestBody BillScanRequest request
    ) {
        User currentUser = getCurrentUser();
        List<MultipartFile> files = new ArrayList<>();

        if (request != null) {
            if (request.getBase64Images() != null) {
                for (int i = 0; i < request.getBase64Images().size(); i++) {
                    MultipartFile mf = decodeBase64ToMultipartFile(request.getBase64Images().get(i), "receipt_page_" + (i + 1));
                    if (mf != null) {
                        files.add(mf);
                    }
                }
            }
            if (request.getBase64Image() != null && !request.getBase64Image().isBlank()) {
                MultipartFile mf = decodeBase64ToMultipartFile(request.getBase64Image(), "receipt_single");
                if (mf != null) {
                    files.add(mf);
                }
            }
        }

        String rawText = request != null ? request.getRawText() : null;
        BillScanPreviewResponseDto preview = billScanService.scanBill(homeId, files, rawText, currentUser);
        return ResponseEntity.ok(ApiResponse.success(preview));
    }

    @PostMapping(value = "/scan", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Scan receipt multipart files or raw text, extract items, detect duplicates, and preview matching")
    public ResponseEntity<ApiResponse<BillScanPreviewResponseDto>> scanBillMultipart(
            @PathVariable UUID homeId,
            @RequestParam(value = "files", required = false) List<MultipartFile> files,
            @RequestParam(value = "rawText", required = false) String rawText,
            @RequestParam(value = "storeName", required = false) String storeName,
            @RequestParam(value = "billDate", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate billDate
    ) {
        User currentUser = getCurrentUser();
        BillScanPreviewResponseDto preview = billScanService.scanBill(homeId, files, rawText, currentUser);
        return ResponseEntity.ok(ApiResponse.success(preview));
    }

    @PostMapping(value = {"/confirm", "/{billId}/confirm"})
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    @Operation(summary = "Confirm scanned bill, atomically update inventory, shopping list, purchase history & price history")
    public ResponseEntity<ApiResponse<BillResponseDto>> confirmBill(
            @PathVariable UUID homeId,
            @PathVariable(required = false) UUID billId,
            @Valid @RequestBody ConfirmBillRequest request
    ) {
        User currentUser = getCurrentUser();
        UUID targetBillId = billId != null ? billId : (request != null ? request.getBillId() : null);
        BillResponseDto confirmed = billConfirmationService.confirmBill(homeId, targetBillId, request, currentUser);
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

    private MultipartFile decodeBase64ToMultipartFile(String base64Str, String baseName) {
        if (base64Str == null || base64Str.trim().isEmpty()) {
            return null;
        }
        try {
            String trimmed = base64Str.trim();
            String contentType = "image/jpeg";
            String extension = ".jpg";

            int commaIndex = trimmed.indexOf(',');
            if (commaIndex != -1 && trimmed.substring(0, commaIndex).contains("base64")) {
                String header = trimmed.substring(0, commaIndex);
                if (header.contains("image/png")) {
                    contentType = "image/png";
                    extension = ".png";
                } else if (header.contains("image/webp")) {
                    contentType = "image/webp";
                    extension = ".webp";
                }
                trimmed = trimmed.substring(commaIndex + 1);
            }

            // Remove any potential whitespace or newlines
            trimmed = trimmed.replaceAll("\\s+", "");
            byte[] bytes = Base64.getDecoder().decode(trimmed);
            if (bytes.length == 0) {
                return null;
            }

            return new CustomInMemoryMultipartFile(
                    baseName,
                    baseName + extension,
                    contentType,
                    bytes
            );
        } catch (Exception e) {
            log.warn("Failed to decode base64 image chunk: {}", e.getMessage());
            return null;
        }
    }

    private User getCurrentUser() {
        try {
            UUID userId = SecurityUtils.getCurrentUserId();
            return userRepository.findById(userId).orElse(null);
        } catch (Exception e) {
            return null;
        }
    }
}
