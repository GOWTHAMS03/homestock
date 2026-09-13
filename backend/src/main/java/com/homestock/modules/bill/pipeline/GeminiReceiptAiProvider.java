package com.homestock.modules.bill.pipeline;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * AI receipt extraction using Google Gemini Multimodal Vision API.
 * Directly reads receipt images and cross-references OCR text with
 * strict no-hallucination rules, financial reconciliation, and Indian retail understanding.
 *
 * Falls back gracefully if the API is unavailable or returns invalid data.
 */
@Component
public class GeminiReceiptAiProvider implements ReceiptAiProvider {

    private static final Logger log = LoggerFactory.getLogger(GeminiReceiptAiProvider.class);

    @Value("${app.bill.ai.gemini.api-key:}")
    private String apiKey;

    @Value("${app.bill.ai.gemini.model:gemini-flash-lite-latest}")
    private String model;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    private static final String EXTRACTION_PROMPT = """
            You are an expert AI for reading shopping receipts and retail bills with maximum precision.
            Your task: Extract every purchased item and financial detail from the bill image (and auxiliary OCR text if provided).

            CRITICAL ACCURACY RULES:
            1. EXAMINE VISUALLY: Inspect the entire bill from top to bottom. Follow the printed column structure (Item Name, Qty, Unit, Rate/MRP, Discount, Net Amount).
            2. EXTRACT EVERY PURCHASED ITEM: Do not skip or truncate any line items. If there are 10 items, extract all 10 items.
            3. NEVER EXTRACT NON-ITEMS:
               - Store header info (Store name, GSTIN, Address, Phone, Bill/Invoice #, Date/Time) are NOT items.
               - Payment lines (UPI, GooglePay, PhonePe, Cash, Card, Net Banking, Change Due, Tendered) are NOT items.
               - Summary/Savings lines (SUBTOTAL, TOTAL GST, CGST, SGST, ROUND OFF, YOU SAVED, TOTAL SAVINGS, POINTS) are NOT items.
               - Barcodes, HSN/SAC codes (e.g. "HSN: 0401"), item serial numbers (1, 2, 3), or batch numbers must NOT be treated as product names, quantities, or prices.
            4. ITEM NORMALIZATION & DETAILS:
               - rawName: The exact printed text for this line item.
               - normalizedName: Cleaned grocery product name (e.g., "AASHIRVAAD ATTA 5KG" -> "Aashirvaad Whole Wheat Atta").
               - brand: Brand name if identifiable (e.g., "Amul", "Tata", "Aashirvaad", "Fortune", "Surf Excel").
               - quantity: Numeric quantity purchased (e.g., 1.0, 2.0, 0.500). If weight-based like "0.750 KG", quantity is 0.750.
               - unit: Standard unit of measure ("kg", "g", "l", "ml", "pcs", "pkt", "bunch", "nos", "bottle", "can").
               - unitPrice: Price per unit / rate (must be > 0).
               - discount: Line-level discount amount if applicable (default 0.00).
               - tax: Line-level tax/GST amount if itemized (default 0.00).
               - lineTotal: The actual final net amount charged for this item.
            5. FINANCIAL RECONCILIATION:
               - Line check: quantity * unitPrice - discount ≈ lineTotal.
               - Bill check: sum(lineTotal) + tax - discount ≈ grandTotal.
               - Accurately extract subtotal, discount, tax (CGST + SGST or GST), and grandTotal.
            6. ZERO HALLUCINATION:
               - If a value is unreadable or uncertain, set it to null and set needsReview: true with a clear reviewReason.
               - Provide honest confidence scores (0.0 to 1.0) for each field.

            RESPOND ONLY with valid JSON in this exact schema (no markdown, no explanation):
            {
              "merchant": {
                "name": {"value": "string or null", "confidence": 0.0},
                "address": {"value": "string or null", "confidence": 0.0},
                "billNumber": {"value": "string or null", "confidence": 0.0}
              },
              "purchaseDate": {"value": "YYYY-MM-DD or null", "confidence": 0.0},
              "purchaseTime": {"value": "HH:MM or null", "confidence": 0.0},
              "paymentMethod": {"value": "CASH/CARD/UPI/null", "confidence": 0.0},
              "totals": {
                "subtotal": {"value": 0.00, "confidence": 0.0},
                "discount": {"value": 0.00, "confidence": 0.0},
                "tax": {"value": 0.00, "confidence": 0.0},
                "grandTotal": {"value": 0.00, "confidence": 0.0}
              },
              "items": [
                {
                  "rawName": "exact text from receipt",
                  "normalizedName": "cleaned product name",
                  "brand": "brand or null",
                  "quantity": 1.0,
                  "unit": "kg/g/l/ml/pcs/pkt",
                  "unitPrice": 0.00,
                  "lineTotal": 0.00,
                  "discount": 0.00,
                  "tax": 0.00,
                  "nameConfidence": 0.0,
                  "quantityConfidence": 0.0,
                  "priceConfidence": 0.0,
                  "needsReview": false,
                  "reviewReason": "reason or null"
                }
              ],
              "overallConfidence": 0.0,
              "notes": "any extraction notes"
            }
            """;

    @Override
    public ReceiptExtractionResult extract(String ocrText, List<String> ocrLines) {
        return extractWithImage(null, null, ocrText, ocrLines);
    }

    @Override
    public ReceiptExtractionResult extractWithImage(byte[] imageBytes, String mimeType, String ocrText, List<String> ocrLines) {
        if (!isAvailable()) {
            log.debug("Gemini AI provider not configured — skipping AI extraction");
            return null;
        }

        boolean hasImage = imageBytes != null && imageBytes.length > 0;
        boolean hasText = ocrText != null && !ocrText.trim().isEmpty();

        if (!hasImage && !hasText) {
            return null;
        }

        try {
            StringBuilder promptBuilder = new StringBuilder(EXTRACTION_PROMPT);
            if (hasText) {
                promptBuilder.append("\n\nAUXILIARY OCR TEXT (reference for character/number verification):\n")
                        .append(ocrText);
            }

            long startTime = System.currentTimeMillis();
            String responseJson = callGeminiApi(imageBytes, mimeType, promptBuilder.toString());

            if (responseJson == null || responseJson.isEmpty()) {
                log.warn("Gemini returned empty response");
                return null;
            }

            ReceiptExtractionResult result = parseGeminiResponse(responseJson);
            long elapsed = System.currentTimeMillis() - startTime;
            log.info("Gemini multimodal extraction completed in {}ms: {} items found (vision={})",
                    elapsed,
                    result != null && result.getItems() != null ? result.getItems().size() : 0,
                    hasImage);
            return result;

        } catch (Exception e) {
            log.error("Gemini receipt extraction failed: {}", e.getMessage());
            return null;
        }
    }

    private String callGeminiApi(byte[] imageBytes, String mimeType, String prompt) throws Exception {
        String url = String.format(
                "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s",
                model, apiKey
        );

        List<Map<String, Object>> parts = new ArrayList<>();

        // If receipt image is available, add as multimodal inlineData for vision analysis
        if (imageBytes != null && imageBytes.length > 0) {
            String safeMime = mimeType != null && mimeType.contains("png") ? "image/png" : "image/jpeg";
            String base64Data = Base64.getEncoder().encodeToString(imageBytes);

            Map<String, Object> inlineData = new LinkedHashMap<>();
            inlineData.put("mimeType", safeMime);
            inlineData.put("data", base64Data);

            Map<String, Object> imagePart = new LinkedHashMap<>();
            imagePart.put("inlineData", inlineData);
            parts.add(imagePart);
        }

        // Add text prompt part
        Map<String, Object> textPart = new LinkedHashMap<>();
        textPart.put("text", prompt);
        parts.add(textPart);

        Map<String, Object> contentMap = new LinkedHashMap<>();
        contentMap.put("parts", parts);

        Map<String, Object> genConfig = new LinkedHashMap<>();
        genConfig.put("temperature", 0.1);
        genConfig.put("topP", 0.8);
        genConfig.put("maxOutputTokens", 4096);
        genConfig.put("responseMimeType", "application/json");

        Map<String, Object> requestPayload = new LinkedHashMap<>();
        requestPayload.put("contents", List.of(contentMap));
        requestPayload.put("generationConfig", genConfig);

        String requestBody = objectMapper.writeValueAsString(requestPayload);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Content-Type", "application/json")
                .timeout(Duration.ofSeconds(30))
                .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() != 200) {
            log.error("Gemini API returned status {}: {}", response.statusCode(),
                    response.body().substring(0, Math.min(500, response.body().length())));
            return null;
        }

        // Parse Gemini response to extract the generated text
        JsonNode root = objectMapper.readTree(response.body());
        JsonNode candidates = root.path("candidates");
        if (candidates.isArray() && !candidates.isEmpty()) {
            JsonNode content = candidates.get(0).path("content").path("parts");
            if (content.isArray() && !content.isEmpty()) {
                String text = content.get(0).path("text").asText("");
                // Clean any markdown code block wrapping
                text = text.trim();
                if (text.startsWith("```json")) text = text.substring(7);
                if (text.startsWith("```")) text = text.substring(3);
                if (text.endsWith("```")) text = text.substring(0, text.length() - 3);
                return text.trim();
            }
        }

        log.warn("Could not extract text from Gemini response structure");
        return null;
    }

    private ReceiptExtractionResult parseGeminiResponse(String json) {
        try {
            JsonNode root = objectMapper.readTree(json);

            // Parse merchant
            JsonNode merchant = root.path("merchant");
            var merchantName = parseConfidentString(merchant.path("name"));
            var merchantAddress = parseConfidentString(merchant.path("address"));
            var billNumber = parseConfidentString(merchant.path("billNumber"));

            var purchaseDate = parseConfidentString(root.path("purchaseDate"));
            var purchaseTime = parseConfidentString(root.path("purchaseTime"));
            var paymentMethod = parseConfidentString(root.path("paymentMethod"));

            // Parse totals
            JsonNode totals = root.path("totals");
            var subtotal = parseConfidentDecimal(totals.path("subtotal"));
            var discount = parseConfidentDecimal(totals.path("discount"));
            var tax = parseConfidentDecimal(totals.path("tax"));
            var grandTotal = parseConfidentDecimal(totals.path("grandTotal"));

            // Parse items
            List<ReceiptExtractionResult.ExtractedReceiptItem> items = new ArrayList<>();
            JsonNode itemsNode = root.path("items");
            if (itemsNode.isArray()) {
                for (JsonNode itemNode : itemsNode) {
                    ReceiptExtractionResult.ExtractedReceiptItem item =
                            ReceiptExtractionResult.ExtractedReceiptItem.builder()
                                    .rawName(getTextOrNull(itemNode, "rawName"))
                                    .normalizedName(getTextOrNull(itemNode, "normalizedName"))
                                    .brand(getTextOrNull(itemNode, "brand"))
                                    .quantity(getDecimalOrDefault(itemNode, "quantity", BigDecimal.ONE))
                                    .unit(getTextOrDefault(itemNode, "unit", "pcs"))
                                    .unitPrice(getDecimalOrDefault(itemNode, "unitPrice", BigDecimal.ZERO))
                                    .lineTotal(getDecimalOrDefault(itemNode, "lineTotal", BigDecimal.ZERO))
                                    .discount(getDecimalOrDefault(itemNode, "discount", BigDecimal.ZERO))
                                    .tax(getDecimalOrDefault(itemNode, "tax", BigDecimal.ZERO))
                                    .nameConfidence(getDecimalOrDefault(itemNode, "nameConfidence", BigDecimal.ZERO))
                                    .quantityConfidence(getDecimalOrDefault(itemNode, "quantityConfidence", BigDecimal.ZERO))
                                    .priceConfidence(getDecimalOrDefault(itemNode, "priceConfidence", BigDecimal.ZERO))
                                    .needsReview(itemNode.path("needsReview").asBoolean(false))
                                    .reviewReason(getTextOrNull(itemNode, "reviewReason"))
                                    .build();

                    // Calculate overall item confidence as weighted min
                    BigDecimal itemConf = calculateItemConfidence(
                            item.getNameConfidence(),
                            item.getQuantityConfidence(),
                            item.getPriceConfidence()
                    );
                    item.setOverallConfidence(itemConf);

                    // Force needsReview if any critical field is low confidence
                    if (itemConf.doubleValue() < 0.70) {
                        item.setNeedsReview(true);
                        if (item.getReviewReason() == null) {
                            item.setReviewReason("Low confidence extraction");
                        }
                    }

                    items.add(item);
                }
            }

            BigDecimal overallConf = getDecimalOrDefault(root, "overallConfidence", BigDecimal.valueOf(0.5));
            String notes = getTextOrNull(root, "notes");

            return ReceiptExtractionResult.builder()
                    .merchantName(merchantName)
                    .merchantAddress(merchantAddress)
                    .billNumber(billNumber)
                    .purchaseDate(purchaseDate)
                    .purchaseTime(purchaseTime)
                    .paymentMethod(paymentMethod)
                    .subtotal(subtotal)
                    .discount(discount)
                    .tax(tax)
                    .grandTotal(grandTotal)
                    .items(items)
                    .overallConfidence(overallConf)
                    .extractionNotes(notes)
                    .aiProvider("gemini")
                    .aiModel(model)
                    .build();

        } catch (Exception e) {
            log.error("Failed to parse Gemini extraction response: {}", e.getMessage());
            return null;
        }
    }

    private ReceiptExtractionResult.ConfidentValue<String> parseConfidentString(JsonNode node) {
        if (node == null || node.isMissingNode() || node.isNull()) {
            return ReceiptExtractionResult.ConfidentValue.unknown();
        }
        // Handle both {"value": "...", "confidence": 0.9} and plain string
        if (node.isObject()) {
            String value = node.path("value").isNull() ? null : node.path("value").asText(null);
            double conf = node.path("confidence").asDouble(0.0);
            if (value == null || value.isEmpty()) return ReceiptExtractionResult.ConfidentValue.unknown();
            return ReceiptExtractionResult.ConfidentValue.confident(value, conf);
        }
        if (node.isTextual()) {
            String value = node.asText(null);
            return value != null ? ReceiptExtractionResult.ConfidentValue.confident(value, 0.5) :
                    ReceiptExtractionResult.ConfidentValue.unknown();
        }
        return ReceiptExtractionResult.ConfidentValue.unknown();
    }

    private ReceiptExtractionResult.ConfidentValue<BigDecimal> parseConfidentDecimal(JsonNode node) {
        if (node == null || node.isMissingNode() || node.isNull()) {
            return ReceiptExtractionResult.ConfidentValue.unknown();
        }
        if (node.isObject()) {
            JsonNode valueNode = node.path("value");
            if (valueNode.isNull() || valueNode.isMissingNode()) return ReceiptExtractionResult.ConfidentValue.unknown();
            double conf = node.path("confidence").asDouble(0.0);
            try {
                BigDecimal value = BigDecimal.valueOf(valueNode.asDouble(0.0));
                return ReceiptExtractionResult.ConfidentValue.confident(value, conf);
            } catch (Exception e) {
                return ReceiptExtractionResult.ConfidentValue.unknown();
            }
        }
        if (node.isNumber()) {
            return ReceiptExtractionResult.ConfidentValue.confident(
                    BigDecimal.valueOf(node.asDouble(0.0)), 0.5);
        }
        return ReceiptExtractionResult.ConfidentValue.unknown();
    }

    private BigDecimal calculateItemConfidence(BigDecimal name, BigDecimal qty, BigDecimal price) {
        // Critical financial fields (price) have higher weight
        double n = name != null ? name.doubleValue() : 0.0;
        double q = qty != null ? qty.doubleValue() : 0.0;
        double p = price != null ? price.doubleValue() : 0.0;

        // Use weighted geometric mean — a single low value drags down the composite
        double weighted = (n * 0.25) + (q * 0.25) + (p * 0.50);

        // Apply penalty if any critical field is very low
        double minCritical = Math.min(p, Math.min(n, q));
        if (minCritical < 0.30) {
            weighted = Math.min(weighted, 0.40);
        }

        return BigDecimal.valueOf(Math.max(0.0, Math.min(1.0, weighted)));
    }

    private String getTextOrNull(JsonNode node, String field) {
        JsonNode child = node.path(field);
        if (child.isNull() || child.isMissingNode()) return null;
        String text = child.asText(null);
        return (text != null && !text.isEmpty() && !"null".equals(text)) ? text : null;
    }

    private String getTextOrDefault(JsonNode node, String field, String defaultValue) {
        String text = getTextOrNull(node, field);
        return text != null ? text : defaultValue;
    }

    private BigDecimal getDecimalOrDefault(JsonNode node, String field, BigDecimal defaultValue) {
        JsonNode child = node.path(field);
        if (child.isNull() || child.isMissingNode()) return defaultValue;
        try {
            return BigDecimal.valueOf(child.asDouble(defaultValue.doubleValue()));
        } catch (Exception e) {
            return defaultValue;
        }
    }

    @Override
    public String getProviderName() {
        return "gemini";
    }

    @Override
    public boolean isAvailable() {
        return apiKey != null && !apiKey.isBlank();
    }
}
