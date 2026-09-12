package com.homestock.modules.bill.service;

import com.homestock.core.common.PagedResponse;
import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.bill.dto.*;
import com.homestock.modules.bill.entity.PurchasedBill;
import com.homestock.modules.bill.entity.PurchasedBillItem;
import com.homestock.modules.bill.matching.ProductMatchResult;
import com.homestock.modules.bill.matching.ProductMatchingEngine;
import com.homestock.modules.bill.ocr.OcrProvider;
import com.homestock.modules.bill.ocr.OcrResult;
import com.homestock.modules.bill.parser.BillParser;
import com.homestock.modules.bill.parser.ParsedBill;
import com.homestock.modules.bill.parser.ParsedBillItem;
import com.homestock.modules.bill.repository.PurchasedBillItemRepository;
import com.homestock.modules.bill.repository.PurchasedBillRepository;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.user.entity.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class BillScanService {

    private static final Logger log = LoggerFactory.getLogger(BillScanService.class);

    private final OcrProvider ocrProvider;
    private final BillParser billParser;
    private final ProductMatchingEngine matchingEngine;
    private final DuplicateBillDetector duplicateDetector;
    private final PurchasedBillRepository billRepository;
    private final PurchasedBillItemRepository billItemRepository;
    private final HomeRepository homeRepository;

    public BillScanService(
            OcrProvider ocrProvider,
            BillParser billParser,
            ProductMatchingEngine matchingEngine,
            DuplicateBillDetector duplicateDetector,
            PurchasedBillRepository billRepository,
            PurchasedBillItemRepository billItemRepository,
            HomeRepository homeRepository
    ) {
        this.ocrProvider = ocrProvider;
        this.billParser = billParser;
        this.matchingEngine = matchingEngine;
        this.duplicateDetector = duplicateDetector;
        this.billRepository = billRepository;
        this.billItemRepository = billItemRepository;
        this.homeRepository = homeRepository;
    }

    @Transactional
    public BillScanPreviewResponseDto scanBill(
            UUID homeId,
            List<MultipartFile> files,
            String rawTextPayload,
            User currentUser
    ) {
        Home home = homeRepository.findById(homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Household not found"));

        String extractedText;
        if (files != null && !files.isEmpty()) {
            List<byte[]> bytesList = new ArrayList<>();
            List<String> mimes = new ArrayList<>();
            for (MultipartFile file : files) {
                try {
                    bytesList.add(file.getBytes());
                    mimes.add(file.getContentType());
                } catch (IOException e) {
                    log.error("Failed to read bill upload image", e);
                }
            }
            OcrResult ocrResult = ocrProvider.extractTextFromImages(bytesList, mimes);
            extractedText = ocrResult.getFullText();
        } else if (rawTextPayload != null && !rawTextPayload.trim().isEmpty()) {
            extractedText = rawTextPayload;
        } else {
            throw new IllegalArgumentException("Either bill image files or raw text payload must be provided");
        }

        // 1. Parse Bill using domain heuristics
        ParsedBill parsed = billParser.parse(extractedText);

        // 2. Check for Duplicate Bill
        DuplicateBillDetector.DuplicateCheckResult dupCheck = duplicateDetector.checkDuplicate(
                homeId,
                parsed.getShopName(),
                parsed.getBillNumber(),
                parsed.getBillDate(),
                parsed.getTotal()
        );

        String idempotencyKey = duplicateDetector.generateIdempotencyKey(
                homeId,
                parsed.getShopName(),
                parsed.getBillNumber(),
                parsed.getBillDate(),
                parsed.getTotal()
        );

        // 3. Save initial draft bill record in SCANNED state
        PurchasedBill bill = PurchasedBill.builder()
                .home(home)
                .shopName(parsed.getShopName())
                .billNumber(parsed.getBillNumber())
                .billDate(parsed.getBillDate() != null ? parsed.getBillDate() : LocalDate.now())
                .subtotal(parsed.getSubtotal() != null ? parsed.getSubtotal() : BigDecimal.ZERO)
                .taxAmount(parsed.getTax() != null ? parsed.getTax() : BigDecimal.ZERO)
                .discountAmount(parsed.getDiscount() != null ? parsed.getDiscount() : BigDecimal.ZERO)
                .totalAmount(parsed.getTotal() != null ? parsed.getTotal() : BigDecimal.ZERO)
                .currency("INR")
                .idempotencyKey(idempotencyKey)
                .status("SCANNED")
                .rawOcrText(extractedText)
                .recordedBy(currentUser)
                .build();

        // If duplicate already exists, we link to existing bill for preview
        if (dupCheck.isExactMatch()) {
            bill = billRepository.findByHomeIdAndIdempotencyKey(homeId, idempotencyKey).orElse(bill);
        } else {
            bill = billRepository.save(bill);
        }

        // 4. Match items against room products and shopping list
        List<BillScanItemPreviewDto> previewItems = new ArrayList<>();
        int autoCount = 0;
        int suggestedCount = 0;
        int newCount = 0;

        for (ParsedBillItem item : parsed.getItems()) {
            ProductMatchResult match = matchingEngine.matchItem(homeId, item);
            Optional<ShoppingListItem> matchedShopping = matchingEngine.findMatchingShoppingItem(homeId, item.getName());

            if ("AUTO_MATCHED".equals(match.getMatchStatus())) autoCount++;
            else if ("SUGGESTED".equals(match.getMatchStatus())) suggestedCount++;
            else newCount++;

            PurchasedBillItem billItem = PurchasedBillItem.builder()
                    .bill(bill)
                    .product(match.getMatchedProduct())
                    .inventoryItem(match.getMatchedInventoryItem())
                    .shoppingListItem(matchedShopping.orElse(null))
                    .rawItemName(item.getName())
                    .normalizedItemName(match.getResolvedName())
                    .quantity(match.getResolvedQuantity())
                    .unit(match.getResolvedUnit())
                    .mrp(item.getMrp())
                    .unitPrice(match.getResolvedUnitPrice())
                    .discount(item.getDiscount())
                    .tax(item.getTax())
                    .finalPrice(match.getResolvedFinalPrice())
                    .standardUnitPrice(match.getStandardUnitPrice())
                    .matchConfidence(match.getConfidence())
                    .matchStatus(match.getMatchStatus())
                    .build();

            if (!dupCheck.isExactMatch()) {
                billItemRepository.save(billItem);
            }

            previewItems.add(BillScanItemPreviewDto.builder()
                    .rawItemName(item.getName())
                    .matchedProductName(match.getResolvedName())
                    .matchedProductId(match.getMatchedProduct() != null ? match.getMatchedProduct().getId() : null)
                    .matchedInventoryItemId(match.getMatchedInventoryItem() != null ? match.getMatchedInventoryItem().getId() : null)
                    .quantity(match.getResolvedQuantity())
                    .unit(match.getResolvedUnit())
                    .mrp(item.getMrp())
                    .unitPrice(match.getResolvedUnitPrice())
                    .discount(item.getDiscount())
                    .tax(item.getTax())
                    .finalPrice(match.getResolvedFinalPrice())
                    .standardUnitPrice(match.getStandardUnitPrice())
                    .matchConfidence(match.getConfidence())
                    .matchStatus(match.getMatchStatus())
                    .matchedShoppingListItemId(matchedShopping.map(ShoppingListItem::getId).orElse(null))
                    .matchedShoppingItemName(matchedShopping.map(ShoppingListItem::getItemName).orElse(null))
                    .build());
        }

        return BillScanPreviewResponseDto.builder()
                .billId(bill.getId())
                .shopName(parsed.getShopName())
                .billNumber(parsed.getBillNumber())
                .billDate(parsed.getBillDate())
                .subtotal(parsed.getSubtotal())
                .tax(parsed.getTax())
                .discount(parsed.getDiscount())
                .total(parsed.getTotal())
                .currency("INR")
                .isDuplicate(dupCheck.isDuplicate())
                .duplicateWarning(dupCheck.warningMessage())
                .existingBillId(dupCheck.existingBillId())
                .items(previewItems)
                .totalItemCount(previewItems.size())
                .autoMatchedCount(autoCount)
                .suggestedCount(suggestedCount)
                .newProductCount(newCount)
                .build();
    }

    @Transactional(readOnly = true)
    public BillResponseDto getBillById(UUID homeId, UUID billId) {
        PurchasedBill bill = billRepository.findById(billId)
                .orElseThrow(() -> new ResourceNotFoundException("Bill not found"));

        if (!bill.getHome().getId().equals(homeId)) {
            throw new org.springframework.security.access.AccessDeniedException("Bill does not belong to this household");
        }

        List<PurchasedBillItem> items = billItemRepository.findByBillId(billId);
        return mapToResponseDto(bill, items);
    }

    @Transactional(readOnly = true)
    public PagedResponse<BillResponseDto> getBills(UUID homeId, Pageable pageable) {
        Page<PurchasedBill> page = billRepository.findByHomeIdOrderByBillDateDesc(homeId, pageable);
        List<BillResponseDto> dtos = page.getContent().stream()
                .map(b -> mapToResponseDto(b, billItemRepository.findByBillId(b.getId())))
                .toList();

        return PagedResponse.<BillResponseDto>builder()
                .content(dtos)
                .page(page.getNumber())
                .size(page.getSize())
                .totalElements(page.getTotalElements())
                .totalPages(page.getTotalPages())
                .last(page.isLast())
                .build();
    }

    private BillResponseDto mapToResponseDto(PurchasedBill bill, List<PurchasedBillItem> items) {
        List<BillItemResponseDto> itemDtos = items.stream().map(i -> BillItemResponseDto.builder()
                .id(i.getId())
                .productId(i.getProduct() != null ? i.getProduct().getId() : null)
                .inventoryItemId(i.getInventoryItem() != null ? i.getInventoryItem().getId() : null)
                .shoppingListItemId(i.getShoppingListItem() != null ? i.getShoppingListItem().getId() : null)
                .rawItemName(i.getRawItemName())
                .normalizedItemName(i.getNormalizedItemName())
                .quantity(i.getQuantity())
                .unit(i.getUnit())
                .mrp(i.getMrp())
                .unitPrice(i.getUnitPrice())
                .discount(i.getDiscount())
                .tax(i.getTax())
                .finalPrice(i.getFinalPrice())
                .standardUnitPrice(i.getStandardUnitPrice())
                .matchConfidence(i.getMatchConfidence())
                .matchStatus(i.getMatchStatus())
                .build()).toList();

        return BillResponseDto.builder()
                .id(bill.getId())
                .homeId(bill.getHome().getId())
                .shopName(bill.getShopName())
                .billNumber(bill.getBillNumber())
                .billDate(bill.getBillDate())
                .subtotal(bill.getSubtotal())
                .taxAmount(bill.getTaxAmount())
                .discountAmount(bill.getDiscountAmount())
                .totalAmount(bill.getTotalAmount())
                .currency(bill.getCurrency())
                .status(bill.getStatus())
                .receiptImageUrl(bill.getReceiptImageUrl())
                .recordedByUserId(bill.getRecordedBy() != null ? bill.getRecordedBy().getId() : null)
                .recordedByName(bill.getRecordedBy() != null ? bill.getRecordedBy().getFullName() : null)
                .confirmedAt(bill.getConfirmedAt())
                .createdAt(bill.getCreatedAt())
                .items(itemDtos)
                .build();
    }
}
