package com.homestock.modules.bill.service;

import com.homestock.core.common.PagedResponse;
import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.bill.dto.*;
import com.homestock.modules.bill.entity.BillExtractionAudit;
import com.homestock.modules.bill.entity.PurchasedBill;
import com.homestock.modules.bill.entity.PurchasedBillItem;
import com.homestock.modules.bill.matching.ProductMatchResult;
import com.homestock.modules.bill.matching.ProductMatchingEngine;
import com.homestock.modules.bill.ocr.OcrProvider;
import com.homestock.modules.bill.ocr.OcrResult;
import com.homestock.modules.bill.parser.BillParser;
import com.homestock.modules.bill.parser.ParsedBill;
import com.homestock.modules.bill.parser.ParsedBillItem;
import com.homestock.modules.bill.pipeline.*;
import com.homestock.modules.bill.repository.BillExtractionAuditRepository;
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
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

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

    // AI Pipeline components
    private final MultiPassOcrOrchestrator ocrOrchestrator;
    private final List<ReceiptAiProvider> aiProviders;
    private final BillMathValidator mathValidator;
    private final ConfidenceScorer confidenceScorer;
    private final BillExtractionAuditRepository auditRepository;
    private final DocumentTypeClassifier documentTypeClassifier;
    private final HandwritingReceiptAiProvider handwritingAiProvider;
    private final ExtractionResultMerger extractionResultMerger;

    public BillScanService(
            OcrProvider ocrProvider,
            BillParser billParser,
            ProductMatchingEngine matchingEngine,
            DuplicateBillDetector duplicateDetector,
            PurchasedBillRepository billRepository,
            PurchasedBillItemRepository billItemRepository,
            HomeRepository homeRepository,
            MultiPassOcrOrchestrator ocrOrchestrator,
            List<ReceiptAiProvider> aiProviders,
            BillMathValidator mathValidator,
            ConfidenceScorer confidenceScorer,
            BillExtractionAuditRepository auditRepository,
            DocumentTypeClassifier documentTypeClassifier,
            HandwritingReceiptAiProvider handwritingAiProvider,
            ExtractionResultMerger extractionResultMerger
    ) {
        this.ocrProvider = ocrProvider;
        this.billParser = billParser;
        this.matchingEngine = matchingEngine;
        this.duplicateDetector = duplicateDetector;
        this.billRepository = billRepository;
        this.billItemRepository = billItemRepository;
        this.homeRepository = homeRepository;
        this.ocrOrchestrator = ocrOrchestrator;
        this.aiProviders = aiProviders;
        this.mathValidator = mathValidator;
        this.confidenceScorer = confidenceScorer;
        this.auditRepository = auditRepository;
        this.documentTypeClassifier = documentTypeClassifier;
        this.handwritingAiProvider = handwritingAiProvider;
        this.extractionResultMerger = extractionResultMerger;
    }

    @Transactional
    public BillScanPreviewResponseDto scanBill(
            UUID homeId,
            List<MultipartFile> files,
            String rawTextPayload,
            User currentUser
    ) {
        long pipelineStart = System.currentTimeMillis();

        Home home = homeRepository.findById(homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Household not found"));

        // ====== STAGE 1: Image/Text Ingestion & Document Classification ======
        String extractedText;
        byte[] primaryImageBytes = null;
        String primaryMimeType = "image/jpeg";
        ImageQualityReport qualityReport = null;
        String ocrProviderName = ocrProvider.getProviderName();
        double ocrConfidence = 0.90;
        com.homestock.modules.bill.entity.DocumentType documentType = com.homestock.modules.bill.entity.DocumentType.PRINTED;

        if (files != null && !files.isEmpty()) {
            // Binary image flow → multi-pass OCR pipeline
            List<byte[]> bytesList = new ArrayList<>();
            List<String> mimes = new ArrayList<>();
            for (MultipartFile file : files) {
                try {
                    byte[] bytes = file.getBytes();
                    bytesList.add(bytes);
                    mimes.add(file.getContentType());
                    if (primaryImageBytes == null) {
                        primaryImageBytes = bytes;
                        primaryMimeType = file.getContentType();
                    }
                } catch (IOException e) {
                    log.error("Failed to read bill upload image", e);
                }
            }

            // Step 1.1: Early Document Classification
            if (primaryImageBytes != null) {
                DocumentTypeClassifier.ClassificationResult classification =
                        documentTypeClassifier.classify(primaryImageBytes, primaryMimeType, null, null);
                documentType = classification.getDocumentType();
                log.info("Document classified as: {} (confidence={}, reason={})",
                        documentType, classification.getConfidence(), classification.getReason());
            }

            // Step 1.2: Run multi-pass OCR (includes quality analysis + preprocessing)
            if (primaryImageBytes != null) {
                MultiPassOcrOrchestrator.MultiPassOcrResult multiPassResult =
                        ocrOrchestrator.runMultiPass(primaryImageBytes, primaryMimeType, documentType);

                qualityReport = multiPassResult.getQualityReport();
                OcrResult bestOcr = multiPassResult.getBestResult();
                extractedText = bestOcr.getFullText();
                ocrConfidence = bestOcr.getConfidence();
                ocrProviderName = bestOcr.getProviderName();
                if (multiPassResult.getProcessedImageBytes() != null) {
                    primaryImageBytes = multiPassResult.getProcessedImageBytes();
                }

                // If multi-page, also process remaining pages
                if (bytesList.size() > 1) {
                    for (int i = 1; i < bytesList.size(); i++) {
                        OcrResult pageResult = ocrProvider.extractText(bytesList.get(i), mimes.get(i));
                        if (pageResult != null && pageResult.getFullText() != null) {
                            extractedText += "\n" + pageResult.getFullText();
                        }
                    }
                }
            } else {
                // Fallback to single-pass
                OcrResult ocrResult = ocrProvider.extractTextFromImages(bytesList, mimes);
                extractedText = ocrResult.getFullText();
                ocrConfidence = ocrResult.getConfidence();
            }
        } else if (rawTextPayload != null && !rawTextPayload.trim().isEmpty()) {
            extractedText = rawTextPayload;
            ocrConfidence = 0.95;
            DocumentTypeClassifier.ClassificationResult textClass =
                    documentTypeClassifier.classify(null, null, rawTextPayload,
                            Arrays.stream(rawTextPayload.split("\\r?\\n")).filter(l -> !l.trim().isEmpty()).toList());
            documentType = textClass.getDocumentType();
        } else {
            throw new IllegalArgumentException("Either bill image files or raw text payload must be provided");
        }

        // ====== STAGE 2: AI Receipt Understanding (Document-Type Aware) ======
        ReceiptExtractionResult aiResult = null;
        String aiProviderName = null;

        List<String> ocrLines = extractedText != null
                ? Arrays.stream(extractedText.split("\\r?\\n")).filter(l -> !l.trim().isEmpty()).toList()
                : List.of();

        if (documentType == com.homestock.modules.bill.entity.DocumentType.HANDWRITTEN) {
            // Dedicated handwriting extraction pipeline
            if (handwritingAiProvider.isAvailable() && primaryImageBytes != null) {
                try {
                    aiResult = handwritingAiProvider.extractWithImage(primaryImageBytes, primaryMimeType, extractedText, ocrLines);
                    if (aiResult != null && !aiResult.getItems().isEmpty()) {
                        aiProviderName = handwritingAiProvider.getProviderName();
                        log.info("AI handwriting extraction via {} produced {} items",
                                aiProviderName, aiResult.getItems().size());
                    }
                } catch (Exception e) {
                    log.warn("Handwriting AI provider failed: {}", e.getMessage());
                }
            }
        } else if (documentType == com.homestock.modules.bill.entity.DocumentType.MIXED) {
            // Mixed pipeline: extract printed and handwritten parts, then merge
            ReceiptExtractionResult printedResult = null;
            ReceiptExtractionResult handwrittenResult = null;

            for (ReceiptAiProvider aiProvider : aiProviders) {
                if (aiProvider.isAvailable() && !(aiProvider instanceof HandwritingReceiptAiProvider)) {
                    try {
                        printedResult = aiProvider.extractWithImage(primaryImageBytes, primaryMimeType, extractedText, ocrLines);
                        if (printedResult != null && !printedResult.getItems().isEmpty()) {
                            break;
                        }
                    } catch (Exception e) {
                        log.warn("Printed AI provider failed in mixed mode: {}", e.getMessage());
                    }
                }
            }

            if (handwritingAiProvider.isAvailable() && primaryImageBytes != null) {
                try {
                    handwrittenResult = handwritingAiProvider.extractWithImage(primaryImageBytes, primaryMimeType, extractedText, ocrLines);
                } catch (Exception e) {
                    log.warn("Handwriting AI provider failed in mixed mode: {}", e.getMessage());
                }
            }

            aiResult = extractionResultMerger.merge(printedResult, handwrittenResult);
            if (aiResult != null && !aiResult.getItems().isEmpty()) {
                aiProviderName = aiResult.getAiProvider();
                log.info("Mixed bill extraction merged {} items", aiResult.getItems().size());
            }
        }

        // Standard or fallback AI extraction (for PRINTED documents or as fallback)
        if (aiResult == null || aiResult.getItems().isEmpty()) {
            for (ReceiptAiProvider aiProvider : aiProviders) {
                if (aiProvider.isAvailable() && !(aiProvider instanceof HandwritingReceiptAiProvider)) {
                    try {
                        aiResult = aiProvider.extractWithImage(primaryImageBytes, primaryMimeType, extractedText, ocrLines);
                        if (aiResult != null && !aiResult.getItems().isEmpty()) {
                            aiProviderName = aiProvider.getProviderName();
                            log.info("AI extraction via {} produced {} items",
                                    aiProviderName, aiResult.getItems().size());
                            break;
                        }
                    } catch (Exception e) {
                        log.warn("AI provider {} failed: {}", aiProvider.getProviderName(), e.getMessage());
                    }
                }
            }
        }

        // ====== STAGE 3: Regex Fallback or Merge ======
        ParsedBill regexParsed = billParser.parse(extractedText);

        // Determine the extraction source — AI if available, regex as fallback
        String shopName;
        LocalDate billDate;
        String billNumber;
        BigDecimal subtotal, tax, discount, total;
        List<ItemExtractionRecord> itemRecords = new ArrayList<>();

        if (aiResult != null && !aiResult.getItems().isEmpty()) {
            // Use AI extraction as primary
            shopName = safeValue(aiResult.getMerchantName());
            if (shopName == null || shopName.isBlank()) shopName = regexParsed.getShopName();

            billDate = parseDateSafe(safeValue(aiResult.getPurchaseDate()));
            if (billDate == null) billDate = regexParsed.getBillDate();

            billNumber = safeValue(aiResult.getBillNumber());
            if (billNumber == null) billNumber = regexParsed.getBillNumber();

            subtotal = safeDecimal(aiResult.getSubtotal());
            if (subtotal == null) subtotal = regexParsed.getSubtotal();

            tax = safeDecimal(aiResult.getTax());
            if (tax == null) tax = regexParsed.getTax();

            discount = safeDecimal(aiResult.getDiscount());
            if (discount == null) discount = regexParsed.getDiscount();

            total = safeDecimal(aiResult.getGrandTotal());
            if (total == null) total = regexParsed.getTotal();

            // Build item records from AI extraction with bidirectional price/total completion
            for (ReceiptExtractionResult.ExtractedReceiptItem aiItem : aiResult.getItems()) {
                BigDecimal qty = aiItem.getQuantity() != null ? aiItem.getQuantity() : BigDecimal.ONE;
                BigDecimal lineTotal = aiItem.getLineTotal();
                BigDecimal unitPrice = aiItem.getUnitPrice();

                if ((lineTotal == null || lineTotal.compareTo(BigDecimal.ZERO) == 0)
                        && unitPrice != null && qty.compareTo(BigDecimal.ZERO) > 0) {
                    BigDecimal disc = aiItem.getDiscount() != null ? aiItem.getDiscount() : BigDecimal.ZERO;
                    lineTotal = qty.multiply(unitPrice).subtract(disc).setScale(2, java.math.RoundingMode.HALF_UP);
                } else if ((unitPrice == null || unitPrice.compareTo(BigDecimal.ZERO) == 0)
                        && lineTotal != null && qty.compareTo(BigDecimal.ZERO) > 0) {
                    unitPrice = lineTotal.divide(qty, 2, java.math.RoundingMode.HALF_UP);
                }

                ParsedBillItem parsed = ParsedBillItem.builder()
                        .name(aiItem.getNormalizedName() != null ? aiItem.getNormalizedName() : aiItem.getRawName())
                        .quantity(qty)
                        .unit(aiItem.getUnit() != null ? aiItem.getUnit() : "pcs")
                        .unitPrice(unitPrice)
                        .mrp(unitPrice)
                        .finalPrice(lineTotal)
                        .discount(aiItem.getDiscount())
                        .tax(aiItem.getTax())
                        .build();

                itemRecords.add(new ItemExtractionRecord(parsed, aiItem));
            }
        } else {
            // Pure regex fallback
            shopName = regexParsed.getShopName();
            billDate = regexParsed.getBillDate();
            billNumber = regexParsed.getBillNumber();
            subtotal = regexParsed.getSubtotal();
            tax = regexParsed.getTax();
            discount = regexParsed.getDiscount();
            total = regexParsed.getTotal();

            for (ParsedBillItem item : regexParsed.getItems()) {
                itemRecords.add(new ItemExtractionRecord(item, null));
            }
        }

        // ====== STAGE 4: Mathematical Validation ======
        BillMathValidator.BillValidationResult validation = null;
        if (aiResult != null && !aiResult.getItems().isEmpty()) {
            validation = mathValidator.validate(aiResult.getItems(), subtotal, tax, discount, total);
        }

        // ====== STAGE 5: Duplicate Check ======
        DuplicateBillDetector.DuplicateCheckResult dupCheck = duplicateDetector.checkDuplicate(
                homeId,
                shopName,
                billNumber,
                billDate,
                total
        );

        String idempotencyKey = duplicateDetector.generateIdempotencyKey(
                homeId, shopName, billNumber, billDate, total
        );

        // Generate image hash for duplicate detection
        String imageHash = primaryImageBytes != null ? hashBytes(primaryImageBytes) : null;

        // ====== STAGE 6: Save Bill Record ======
        String safeShop = sanitize(shopName);
        if (safeShop == null || safeShop.isBlank()) safeShop = "Retail Store";
        String safeBillNo = sanitize(billNumber);
        String safeOcrText = sanitize(extractedText);

        BigDecimal imageQualityScore = qualityReport != null ? qualityReport.getQualityScore() : null;

        PurchasedBill bill = PurchasedBill.builder()
                .home(home)
                .documentType(documentType)
                .shopName(safeShop)
                .billNumber(safeBillNo)
                .billDate(billDate != null ? billDate : LocalDate.now())
                .subtotal(subtotal != null ? subtotal : BigDecimal.ZERO)
                .taxAmount(tax != null ? tax : BigDecimal.ZERO)
                .discountAmount(discount != null ? discount : BigDecimal.ZERO)
                .totalAmount(total != null ? total : BigDecimal.ZERO)
                .currency("INR")
                .idempotencyKey(idempotencyKey)
                .status("SCANNED")
                .processingStatus("READY_FOR_REVIEW")
                .rawOcrText(safeOcrText)
                .recordedBy(currentUser)
                .imageQualityScore(imageQualityScore)
                .ocrProvider(ocrProviderName)
                .aiProvider(aiProviderName)
                .imageHash(imageHash)
                .validationStatus(validation != null ? validation.getStatus() : null)
                .validationDiscrepancy(validation != null ? validation.getDiscrepancy() : null)
                .processingDurationMs((int) (System.currentTimeMillis() - pipelineStart))
                .build();

        if (dupCheck.isExactMatch()) {
            bill = billRepository.findByHomeIdAndIdempotencyKey(homeId, idempotencyKey).orElse(bill);
        } else {
            bill = billRepository.save(bill);
        }

        // Save audit records
        if (!dupCheck.isExactMatch()) {
            saveAudit(bill, "OCR", ocrProviderName, null, null,
                    safeOcrText, BigDecimal.valueOf(ocrConfidence));

            if (aiResult != null) {
                saveAudit(bill, "AI_EXTRACTION", aiProviderName,
                        aiResult.getAiModel(), safeOcrText, null,
                        aiResult.getOverallConfidence());
            }

            if (validation != null) {
                saveAudit(bill, "VALIDATION", null, null, null,
                        validation.getStatus(), BigDecimal.valueOf(validation.isReconciled() ? 1.0 : 0.5));
            }
        }

        // ====== STAGE 7: Product Matching ======
        List<BillScanItemPreviewDto> previewItems = new ArrayList<>();
        List<BigDecimal> matchConfidences = new ArrayList<>();
        int autoCount = 0, suggestedCount = 0, newCount = 0;
        int needsReviewCount = 0;

        for (ItemExtractionRecord record : itemRecords) {
            ParsedBillItem item = record.parsed();
            ReceiptExtractionResult.ExtractedReceiptItem aiItem = record.aiItem();

            ProductMatchResult match = matchingEngine.matchItem(homeId, item);
            Optional<ShoppingListItem> matchedShopping = matchingEngine.findMatchingShoppingItem(homeId, item.getName());
            matchConfidences.add(match.getConfidence());

            if ("AUTO_MATCHED".equals(match.getMatchStatus())) autoCount++;
            else if ("SUGGESTED".equals(match.getMatchStatus())) suggestedCount++;
            else newCount++;

            String safeItemName = sanitize(item.getName());
            String safeNormName = sanitize(match.getResolvedName());

            // Determine per-field confidences
            BigDecimal nameConf = aiItem != null ? aiItem.getNameConfidence() : null;
            BigDecimal qtyConf = aiItem != null ? aiItem.getQuantityConfidence() : null;
            BigDecimal priceConf = aiItem != null ? aiItem.getPriceConfidence() : null;
            boolean itemNeedsReview = aiItem != null && aiItem.isNeedsReview();
            String reviewReason = aiItem != null ? aiItem.getReviewReason() : null;

            // Force review for low match confidence
            if (match.getConfidence().doubleValue() < 80.0) {
                itemNeedsReview = true;
                reviewReason = reviewReason != null ? reviewReason + "; Low inventory match confidence"
                        : "Low inventory match confidence";
            }

            if (itemNeedsReview) needsReviewCount++;

            PurchasedBillItem billItem = PurchasedBillItem.builder()
                    .bill(bill)
                    .product(match.getMatchedProduct())
                    .inventoryItem(match.getMatchedInventoryItem())
                    .shoppingListItem(matchedShopping.orElse(null))
                    .rawItemName(safeItemName != null ? safeItemName : "Item")
                    .normalizedItemName(safeNormName != null ? safeNormName : "Item")
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
                    .ocrConfidence(BigDecimal.valueOf(ocrConfidence))
                    .nameConfidence(nameConf)
                    .quantityConfidence(qtyConf)
                    .priceConfidence(priceConf)
                    .needsReview(itemNeedsReview)
                    .reviewReason(reviewReason)
                    .aiRawName(aiItem != null ? aiItem.getRawName() : null)
                    .build();

            if (!dupCheck.isExactMatch()) {
                billItemRepository.save(billItem);
            }

            previewItems.add(BillScanItemPreviewDto.builder()
                    .rawItemName(item.getName())
                    .matchedProductName(match.getResolvedName())
                    .categoryName(match.getResolvedCategory())
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
                    .nameConfidence(nameConf)
                    .quantityConfidence(qtyConf)
                    .priceConfidence(priceConf)
                    .needsReview(itemNeedsReview)
                    .reviewReason(reviewReason)
                    .suggestedMatches(match.getSuggestedMatches())
                    .build());
        }

        // ====== STAGE 8: Overall Confidence Scoring ======
        ConfidenceScorer.BillConfidenceResult confidenceResult = confidenceScorer.calculateBillConfidence(
                imageQualityScore, ocrConfidence, aiResult, validation, matchConfidences, documentType
        );

        // Update bill with final confidence
        if (!dupCheck.isExactMatch()) {
            bill.setOverallConfidence(confidenceResult.getOverallConfidence());
            bill.setNeedsReview(needsReviewCount > 0);
            String itemFingerprint = generateItemFingerprint(itemRecords);
            bill.setItemFingerprint(itemFingerprint);
            billRepository.save(bill);
        }

        int pipelineDuration = (int) (System.currentTimeMillis() - pipelineStart);
        log.info("Bill scan pipeline completed in {}ms: {} items, confidence={}, needsReview={}, aiProvider={}, docType={}",
                pipelineDuration, previewItems.size(), confidenceResult.getOverallConfidence(),
                needsReviewCount, aiProviderName, documentType);

        return BillScanPreviewResponseDto.builder()
                .billId(bill.getId())
                .shopName(safeShop)
                .billNumber(safeBillNo)
                .billDate(billDate)
                .subtotal(subtotal)
                .tax(tax)
                .discount(discount)
                .total(total)
                .currency("INR")
                .isDuplicate(dupCheck.isDuplicate())
                .duplicateWarning(dupCheck.warningMessage())
                .existingBillId(dupCheck.existingBillId())
                .items(previewItems)
                .totalItemCount(previewItems.size())
                .autoMatchedCount(autoCount)
                .suggestedCount(suggestedCount)
                .newProductCount(newCount)
                // New pipeline fields
                .documentType(documentType)
                .imageQualityScore(imageQualityScore)
                .imageQualityMessage(qualityReport != null ? qualityReport.getMessage() : null)
                .ocrConfidence(BigDecimal.valueOf(ocrConfidence).setScale(2, RoundingMode.HALF_UP))
                .overallConfidence(confidenceResult.getOverallConfidence())
                .processingStatus("READY_FOR_REVIEW")
                .needsReviewCount(needsReviewCount)
                .validationStatus(validation != null ? validation.getStatus() : null)
                .validationDiscrepancy(validation != null ? validation.getDiscrepancy() : null)
                .aiProvider(aiProviderName)
                .processingDurationMs(pipelineDuration)
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

    @Transactional
    public void deleteBill(UUID homeId, UUID billId) {
        PurchasedBill bill = billRepository.findById(billId)
                .orElseThrow(() -> new ResourceNotFoundException("Bill not found"));

        if (!bill.getHome().getId().equals(homeId)) {
            throw new org.springframework.security.access.AccessDeniedException("Bill does not belong to this household");
        }

        if ("CONFIRMED".equals(bill.getStatus())) {
            throw new IllegalStateException("Cannot delete a confirmed bill — inventory has already been updated");
        }

        billRepository.delete(bill);
        log.info("Deleted bill {} (status={})", billId, bill.getStatus());
    }

    // ====== Helper Methods ======

    private record ItemExtractionRecord(
            ParsedBillItem parsed,
            ReceiptExtractionResult.ExtractedReceiptItem aiItem
    ) {}

    private void saveAudit(PurchasedBill bill, String stage, String provider, String model,
                           String rawInput, String rawOutput, BigDecimal confidence) {
        try {
            BillExtractionAudit audit = BillExtractionAudit.builder()
                    .bill(bill)
                    .stage(stage)
                    .provider(provider)
                    .model(model)
                    .rawInput(truncate(rawInput, 5000))
                    .rawOutput(truncate(rawOutput, 5000))
                    .confidence(confidence)
                    .build();
            auditRepository.save(audit);
        } catch (Exception e) {
            log.warn("Failed to save audit record for stage {}: {}", stage, e.getMessage());
        }
    }

    private String safeValue(ReceiptExtractionResult.ConfidentValue<String> cv) {
        if (cv == null || cv.getValue() == null) return null;
        return cv.getValue();
    }

    private BigDecimal safeDecimal(ReceiptExtractionResult.ConfidentValue<BigDecimal> cv) {
        if (cv == null || cv.getValue() == null) return null;
        return cv.getValue().setScale(2, RoundingMode.HALF_UP);
    }

    private LocalDate parseDateSafe(String dateStr) {
        if (dateStr == null || dateStr.isBlank()) return null;
        try {
            return LocalDate.parse(dateStr.trim(), DateTimeFormatter.ISO_LOCAL_DATE);
        } catch (Exception e) {
            // Try common formats
            for (String fmt : List.of("dd/MM/yyyy", "dd-MM-yyyy", "dd.MM.yyyy", "d/M/yyyy")) {
                try {
                    return LocalDate.parse(dateStr.trim(), DateTimeFormatter.ofPattern(fmt));
                } catch (Exception ignored) {}
            }
            return null;
        }
    }

    private String hashBytes(byte[] bytes) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(bytes);
            return HexFormat.of().formatHex(hash);
        } catch (Exception e) {
            return null;
        }
    }

    private String generateItemFingerprint(List<ItemExtractionRecord> items) {
        try {
            String sorted = items.stream()
                    .map(r -> (r.parsed().getName() + ":" + r.parsed().getQuantity()).toLowerCase())
                    .sorted()
                    .collect(Collectors.joining("|"));
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(sorted.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash).substring(0, 32);
        } catch (Exception e) {
            return null;
        }
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
                .nameConfidence(i.getNameConfidence())
                .quantityConfidence(i.getQuantityConfidence())
                .priceConfidence(i.getPriceConfidence())
                .needsReview(i.getNeedsReview() != null && i.getNeedsReview())
                .reviewReason(i.getReviewReason())
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
                .documentType(bill.getDocumentType())
                .processingStatus(bill.getProcessingStatus())
                .receiptImageUrl(bill.getReceiptImageUrl())
                .recordedByUserId(bill.getRecordedBy() != null ? bill.getRecordedBy().getId() : null)
                .recordedByName(bill.getRecordedBy() != null ? bill.getRecordedBy().getFullName() : null)
                .confirmedAt(bill.getConfirmedAt())
                .createdAt(bill.getCreatedAt())
                .overallConfidence(bill.getOverallConfidence())
                .needsReview(bill.getNeedsReview() != null && bill.getNeedsReview())
                .validationStatus(bill.getValidationStatus())
                .items(itemDtos)
                .build();
    }

    private String sanitize(String input) {
        if (input == null) return null;
        String s = input.replace("\u0000", "").replaceAll("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]", "").trim();
        return s.isEmpty() ? null : s;
    }

    private String truncate(String s, int maxLen) {
        if (s == null) return null;
        return s.length() > maxLen ? s.substring(0, maxLen) : s;
    }
}
