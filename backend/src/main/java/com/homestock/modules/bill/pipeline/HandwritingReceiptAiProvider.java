package com.homestock.modules.bill.pipeline;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.*;

/**
 * AI extraction provider specialized for handwritten bills, shopping lists,
 * Tamil handwriting, Tanglish notes, and poor/tilted camera photos.
 *
 * Employs Gemini Multimodal Vision with strict zero-hallucination policies
 * and bidirectional quantity/price extraction.
 */
@Component
@Order(2)
public class HandwritingReceiptAiProvider implements ReceiptAiProvider {

    private static final Logger log = LoggerFactory.getLogger(HandwritingReceiptAiProvider.class);

    @Value("${app.bill.ai.gemini.api-key:}")
    private String apiKey;

    @Value("${app.bill.ai.gemini.model:gemini-flash-lite-latest}")
    private String model;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(15))
            .build();

    private static final String HANDWRITING_EXTRACTION_PROMPT = """
            You are an expert AI multimodal document reader specialized in deciphering HANDWRITTEN retail bills, grocery chits, handwritten shopping lists, and store slips.
            The input may contain English handwriting, Tamil script handwriting (தமிழ்), Tanglish (Tamil words written in English letters), numbers, fractions (1/2, 1/4, 3/4), or mixed printed + handwritten text.
            The photo might be taken by a phone camera with tilt, uneven lighting, shadows, or faint ink/pencil.

            CRITICAL ACCURACY & NO-HALLUCINATION RULES:
            1. EXAMINE THOROUGHLY: Follow each handwritten line from top to bottom. Pay close attention to strokes, columns, and item groupings.
            2. MULTI-LANGUAGE & SCRIPT UNDERSTANDING:
               - Tamil script: e.g., "அரிசி" -> English normalized: "Rice"; "துவரம்பருப்பு" -> "Toor Dal"; "சர்க்கரை" -> "Sugar"; "எண்ணெய்" -> "Oil"; "பால்" -> "Milk".
               - Tanglish: e.g., "arisi" -> "Rice"; "thuvaram paruppu" -> "Toor Dal"; "kadugu" -> "Mustard"; "seeragam" -> "Cumin"; "cheeni" / "sarkarai" -> "Sugar"; "vengayam" -> "Onion"; "thakkali" -> "Tomato".
               - English handwriting: standard grocery and provision items.
            3. FOR EACH EXTRACTED ITEM:
               - rawName: The exact handwritten text as written (in original Tamil or English letters).
               - normalizedName: The standard canonical English grocery name (e.g., "Toor Dal", "Basmati Rice", "Sugar", "Sunflower Oil").
               - brand: Brand if identifiable (e.g., "Aashirvaad", "Tata", "Fortune", "Amul", "Sakthi"), otherwise null.
               - quantity: Numeric value. Handle handwritten fractions:
                 * "1/2 kg" or "1/2" -> 0.500
                 * "1/4 kg" or "kaal kilo" -> 0.250
                 * "3/4 kg" or "mukkaal kilo" -> 0.750
                 * Default to 1.0 if not specified.
               - unit: Standard unit ("kg", "g", "l", "ml", "pcs", "pkt", "bunch", "nos").
               - unitPrice: Price per unit if written, otherwise null.
               - lineTotal: Total line price if written, otherwise null.
               - discount: Discount if indicated, otherwise 0.00.
               - tax: Tax if indicated, otherwise 0.00.
               - needsReview: Set to true if handwriting is faint, ambiguous, crossed out, or if price is missing.
               - reviewReason: Clear explanation if needsReview is true (e.g. "Price not mentioned on shopping list", "Faint handwriting stroke").
            4. SHOPPING LIST HANDLING:
               - Handwritten shopping lists often list items and quantities WITHOUT prices. In that case, extract quantity and name, leave prices as null, and set needsReview: true.
            5. ZERO HALLUCINATION POLICY:
               - NEVER invent items that are not written.
               - If a line is crossed out or scratched over, do NOT include it.
               - If a word is completely unreadable, do NOT guess wildly; write "[Unreadable handwriting]" and set nameConfidence: 0.10, needsReview: true.
               - Be honest with confidence scores (0.0 to 1.0).

            RESPOND ONLY with valid JSON in this schema (no markdown, no preamble):
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
                  "rawName": "handwritten text as written",
                  "normalizedName": "canonical English grocery name",
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
              "notes": "handwriting extraction notes"
            }
            """;

    @Override
    public String getProviderName() {
        return "gemini-handwriting";
    }

    @Override
    public boolean isAvailable() {
        return apiKey != null && !apiKey.trim().isEmpty();
    }

    @Override
    public ReceiptExtractionResult extract(String ocrText, List<String> ocrLines) {
        return extractWithImage(null, null, ocrText, ocrLines);
    }

    @Override
    public ReceiptExtractionResult extractWithImage(byte[] imageBytes, String mimeType, String ocrText, List<String> ocrLines) {
        if (!isAvailable()) {
            log.debug("Gemini handwriting provider not configured (missing API key)");
            return null;
        }

        if (imageBytes == null || imageBytes.length == 0) {
            log.debug("No image provided for handwriting extraction");
            return null;
        }

        try {
            long startTime = System.currentTimeMillis();
            String responseJson = callGeminiApi(imageBytes, mimeType, HANDWRITING_EXTRACTION_PROMPT);

            if (responseJson == null || responseJson.isEmpty()) {
                log.warn("Gemini handwriting returned empty response");
                return null;
            }

            ReceiptExtractionResult result = parseGeminiResponse(responseJson);
            long elapsed = System.currentTimeMillis() - startTime;
            log.info("Gemini handwriting extraction completed in {}ms: {} items found",
                    elapsed,
                    result != null && result.getItems() != null ? result.getItems().size() : 0);
            return result;

        } catch (Exception e) {
            log.error("Gemini handwriting extraction failed: {}", e.getMessage(), e);
            return null;
        }
    }

    private String callGeminiApi(byte[] imageBytes, String mimeType, String prompt) throws Exception {
        String url = String.format(
                "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s",
                model, apiKey
        );

        String effectiveMime = (mimeType != null && !mimeType.isEmpty()) ? mimeType : "image/jpeg";
        String base64Image = Base64.getEncoder().encodeToString(imageBytes);

        Map<String, Object> inlineData = Map.of(
                "mimeType", effectiveMime,
                "data", base64Image
        );

        Map<String, Object> imagePart = Map.of("inlineData", inlineData);
        Map<String, Object> textPart = Map.of("text", prompt);

        Map<String, Object> contentMap = Map.of(
                "parts", List.of(imagePart, textPart)
        );

        Map<String, Object> genConfig = Map.of(
                "temperature", 0.05,
                "maxOutputTokens", 8192,
                "responseMimeType", "application/json"
        );

        Map<String, Object> requestPayload = new LinkedHashMap<>();
        requestPayload.put("contents", List.of(contentMap));
        requestPayload.put("generationConfig", genConfig);

        String requestBody = objectMapper.writeValueAsString(requestPayload);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Content-Type", "application/json")
                .timeout(Duration.ofSeconds(45))
                .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() != 200) {
            log.error("Gemini Handwriting API returned status {}: {}", response.statusCode(),
                    response.body().substring(0, Math.min(500, response.body().length())));
            return null;
        }

        JsonNode root = objectMapper.readTree(response.body());
        JsonNode candidates = root.path("candidates");
        if (candidates.isArray() && !candidates.isEmpty()) {
            JsonNode content = candidates.get(0).path("content").path("parts");
            if (content.isArray() && !content.isEmpty()) {
                String text = content.get(0).path("text").asText("");
                text = text.trim();
                if (text.startsWith("```json")) text = text.substring(7);
                if (text.startsWith("```")) text = text.substring(3);
                if (text.endsWith("```")) text = text.substring(0, text.length() - 3);
                return text.trim();
            }
        }

        return null;
    }

    private ReceiptExtractionResult parseGeminiResponse(String json) {
        try {
            JsonNode root = objectMapper.readTree(json);

            JsonNode merchant = root.path("merchant");
            var merchantName = parseConfidentString(merchant.path("name"));
            var merchantAddress = parseConfidentString(merchant.path("address"));
            var billNumber = parseConfidentString(merchant.path("billNumber"));

            var purchaseDate = parseConfidentString(root.path("purchaseDate"));
            var purchaseTime = parseConfidentString(root.path("purchaseTime"));
            var paymentMethod = parseConfidentString(root.path("paymentMethod"));

            JsonNode totals = root.path("totals");
            var subtotal = parseConfidentDecimal(totals.path("subtotal"));
            var discount = parseConfidentDecimal(totals.path("discount"));
            var tax = parseConfidentDecimal(totals.path("tax"));
            var grandTotal = parseConfidentDecimal(totals.path("grandTotal"));

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
                                    .unitPrice(getDecimalOrDefault(itemNode, "unitPrice", null))
                                    .lineTotal(getDecimalOrDefault(itemNode, "lineTotal", null))
                                    .discount(getDecimalOrDefault(itemNode, "discount", BigDecimal.ZERO))
                                    .tax(getDecimalOrDefault(itemNode, "tax", BigDecimal.ZERO))
                                    .nameConfidence(getDecimalOrDefault(itemNode, "nameConfidence", BigDecimal.valueOf(0.60)))
                                    .quantityConfidence(getDecimalOrDefault(itemNode, "quantityConfidence", BigDecimal.valueOf(0.60)))
                                    .priceConfidence(getDecimalOrDefault(itemNode, "priceConfidence", BigDecimal.valueOf(0.50)))
                                    .needsReview(itemNode.path("needsReview").asBoolean(false))
                                    .reviewReason(getTextOrNull(itemNode, "reviewReason"))
                                    .build();

                    // If price is missing or zero, flag for review (typical of shopping lists)
                    if (item.getLineTotal() == null || item.getLineTotal().compareTo(BigDecimal.ZERO) == 0) {
                        item.setNeedsReview(true);
                        if (item.getReviewReason() == null) {
                            item.setReviewReason("Price not specified on handwritten note");
                        }
                    }

                    // Calculate item overall confidence
                    BigDecimal itemConf = calculateItemConfidence(
                            item.getNameConfidence(),
                            item.getQuantityConfidence(),
                            item.getPriceConfidence()
                    );
                    item.setOverallConfidence(itemConf);

                    if (itemConf.doubleValue() < 0.65) {
                        item.setNeedsReview(true);
                        if (item.getReviewReason() == null) {
                            item.setReviewReason("Low confidence handwriting extraction");
                        }
                    }

                    items.add(item);
                }
            }

            BigDecimal overallConf = getDecimalOrDefault(root, "overallConfidence", BigDecimal.valueOf(0.70));
            String notes = root.path("notes").asText(null);

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
                    .aiProvider(getProviderName())
                    .build();

        } catch (Exception e) {
            log.error("Failed to parse Gemini handwriting response: {}", e.getMessage());
            return null;
        }
    }

    private BigDecimal calculateItemConfidence(BigDecimal name, BigDecimal qty, BigDecimal price) {
        double n = name != null ? name.doubleValue() : 0.5;
        double q = qty != null ? qty.doubleValue() : 0.5;
        double p = price != null ? price.doubleValue() : 0.5;
        double weighted = (n * 0.35) + (q * 0.30) + (p * 0.35);
        return BigDecimal.valueOf(Math.max(0.0, Math.min(1.0, weighted))).setScale(2, RoundingMode.HALF_UP);
    }

    private ReceiptExtractionResult.ConfidentValue<String> parseConfidentString(JsonNode node) {
        if (node == null || node.isMissingNode() || node.isNull()) {
            return ReceiptExtractionResult.ConfidentValue.unknown();
        }
        if (node.isObject()) {
            String val = node.path("value").asText(null);
            double conf = node.path("confidence").asDouble(0.0);
            return val != null ? ReceiptExtractionResult.ConfidentValue.confident(val, conf)
                    : ReceiptExtractionResult.ConfidentValue.unknown();
        }
        if (node.isTextual()) {
            return ReceiptExtractionResult.ConfidentValue.confident(node.asText(null), 0.5);
        }
        return ReceiptExtractionResult.ConfidentValue.unknown();
    }

    private ReceiptExtractionResult.ConfidentValue<BigDecimal> parseConfidentDecimal(JsonNode node) {
        if (node == null || node.isMissingNode() || node.isNull()) {
            return ReceiptExtractionResult.ConfidentValue.unknown();
        }
        if (node.isObject()) {
            JsonNode valNode = node.path("value");
            if (valNode.isNull() || valNode.isMissingNode()) return ReceiptExtractionResult.ConfidentValue.unknown();
            double conf = node.path("confidence").asDouble(0.0);
            try {
                BigDecimal val = BigDecimal.valueOf(valNode.asDouble(0.0));
                return ReceiptExtractionResult.ConfidentValue.confident(val, conf);
            } catch (Exception e) {
                return ReceiptExtractionResult.ConfidentValue.unknown();
            }
        }
        if (node.isNumber()) {
            return ReceiptExtractionResult.ConfidentValue.confident(BigDecimal.valueOf(node.asDouble(0.0)), 0.5);
        }
        return ReceiptExtractionResult.ConfidentValue.unknown();
    }

    private String getTextOrNull(JsonNode node, String field) {
        JsonNode f = node.path(field);
        return (f.isMissingNode() || f.isNull() || f.asText().isBlank()) ? null : f.asText().trim();
    }

    private String getTextOrDefault(JsonNode node, String field, String def) {
        JsonNode f = node.path(field);
        return (f.isMissingNode() || f.isNull() || f.asText().isBlank()) ? def : f.asText().trim();
    }

    private BigDecimal getDecimalOrDefault(JsonNode node, String field, BigDecimal def) {
        JsonNode f = node.path(field);
        if (f.isMissingNode() || f.isNull()) return def;
        try {
            return BigDecimal.valueOf(f.asDouble()).setScale(2, RoundingMode.HALF_UP);
        } catch (Exception e) {
            return def;
        }
    }
}
