package com.homestock.modules.bill.pipeline;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.homestock.modules.bill.entity.DocumentType;
import com.homestock.modules.bill.matching.TamilNormalizationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.*;
import java.util.regex.Pattern;

/**
 * Classifies uploaded bill documents into PRINTED, HANDWRITTEN, or MIXED.
 * Uses a fast, lightweight multimodal Gemini check when image is present,
 * backed by a robust heuristic fallback.
 */
@Service
public class DocumentTypeClassifier {

    private static final Logger log = LoggerFactory.getLogger(DocumentTypeClassifier.class);

    @Value("${app.bill.ai.gemini.api-key:}")
    private String apiKey;

    @Value("${app.bill.ai.gemini.model:gemini-flash-lite-latest}")
    private String model;

    private final TamilNormalizationService tamilNormalizationService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(6))
            .build();

    private static final Pattern PRINTED_RECEIPT_MARKERS = Pattern.compile(
            "\\b(GSTIN|INVOICE|CASHIER|TAX INVOICE|BILL NO|SUBTOTAL|TOTAL AMOUNT|POS|TENDER|CHANGE DUE|THANK YOU|VISIT AGAIN)\\b",
            Pattern.CASE_INSENSITIVE
    );

    private static final String CLASSIFY_PROMPT = """
            Analyze this uploaded shopping/retail document image.
            Classify its type into EXACTLY one of the following:
            - "PRINTED": Fully printed supermarket/grocery receipt, POS thermal bill, cash register printout, or typed invoice.
            - "HANDWRITTEN": Handwritten grocery bill, handwritten shopping list, chit, handwritten item+price tally, diary page, or slip written with pen/pencil (can be in English, Tamil, Tanglish, or mixed).
            - "MIXED": Document containing BOTH printed text (like printed letterhead, printed table structure, or printed bill) AND handwritten lines, prices, ticks, or item additions.

            Respond ONLY with valid JSON:
            {
              "documentType": "PRINTED|HANDWRITTEN|MIXED",
              "confidence": 0.0 to 1.0,
              "hasTamil": true or false,
              "hasHandwriting": true or false,
              "hasPrintedText": true or false,
              "reason": "one concise sentence explaining visual cues"
            }
            """;

    public DocumentTypeClassifier(TamilNormalizationService tamilNormalizationService) {
        this.tamilNormalizationService = tamilNormalizationService;
    }

    /**
     * Classifies the document type using multimodal AI visual inspection,
     * falling back to text heuristics if AI is unconfigured or fails.
     */
    public ClassificationResult classify(byte[] imageBytes, String mimeType, String ocrText, List<String> ocrLines) {
        if (imageBytes != null && imageBytes.length > 0 && apiKey != null && !apiKey.trim().isEmpty()) {
            try {
                ClassificationResult aiClassification = classifyViaAi(imageBytes, mimeType);
                if (aiClassification != null) {
                    log.info("Document classified by AI as: {} (confidence={}, reason={})",
                            aiClassification.getDocumentType(),
                            aiClassification.getConfidence(),
                            aiClassification.getReason());
                    return aiClassification;
                }
            } catch (Exception e) {
                log.warn("AI document classification failed, falling back to heuristics: {}", e.getMessage());
            }
        }

        // Heuristic fallback
        return classifyHeuristically(ocrText, ocrLines);
    }

    private ClassificationResult classifyViaAi(byte[] imageBytes, String mimeType) throws Exception {
        String effectiveMime = (mimeType != null && !mimeType.isEmpty()) ? mimeType : "image/jpeg";
        String base64Image = Base64.getEncoder().encodeToString(imageBytes);

        String url = String.format(
                "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s",
                model, apiKey
        );

        Map<String, Object> inlineData = Map.of(
                "mimeType", effectiveMime,
                "data", base64Image
        );

        Map<String, Object> imagePart = Map.of("inlineData", inlineData);
        Map<String, Object> textPart = Map.of("text", CLASSIFY_PROMPT);

        Map<String, Object> contentMap = Map.of(
                "parts", List.of(imagePart, textPart)
        );

        Map<String, Object> genConfig = Map.of(
                "temperature", 0.0,
                "maxOutputTokens", 256,
                "responseMimeType", "application/json"
        );

        Map<String, Object> requestPayload = new LinkedHashMap<>();
        requestPayload.put("contents", List.of(contentMap));
        requestPayload.put("generationConfig", genConfig);

        String requestBody = objectMapper.writeValueAsString(requestPayload);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Content-Type", "application/json")
                .timeout(Duration.ofSeconds(10))
                .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() != 200) {
            log.warn("Gemini classify API returned status {}", response.statusCode());
            return null;
        }

        JsonNode root = objectMapper.readTree(response.body());
        JsonNode candidates = root.path("candidates");
        if (candidates.isArray() && !candidates.isEmpty()) {
            JsonNode content = candidates.get(0).path("content").path("parts");
            if (content.isArray() && !content.isEmpty()) {
                String text = content.get(0).path("text").asText("").trim();
                if (text.startsWith("```json")) text = text.substring(7);
                if (text.startsWith("```")) text = text.substring(3);
                if (text.endsWith("```")) text = text.substring(0, text.length() - 3);

                JsonNode parsed = objectMapper.readTree(text.trim());
                String typeStr = parsed.path("documentType").asText("PRINTED").toUpperCase().trim();
                double conf = parsed.path("confidence").asDouble(0.85);
                String reason = parsed.path("reason").asText("AI visual classification");
                boolean hasTamil = parsed.path("hasTamil").asBoolean(false);

                DocumentType docType = switch (typeStr) {
                    case "HANDWRITTEN" -> DocumentType.HANDWRITTEN;
                    case "MIXED" -> DocumentType.MIXED;
                    default -> DocumentType.PRINTED;
                };

                return ClassificationResult.builder()
                        .documentType(docType)
                        .confidence(conf)
                        .reason(reason)
                        .hasTamil(hasTamil)
                        .build();
            }
        }

        return null;
    }

    private ClassificationResult classifyHeuristically(String ocrText, List<String> ocrLines) {
        if (ocrText == null || ocrText.isBlank()) {
            // Default to PRINTED to preserve default pipeline behavior
            return ClassificationResult.builder()
                    .documentType(DocumentType.PRINTED)
                    .confidence(0.60)
                    .reason("Heuristic: No text provided, defaulting to PRINTED")
                    .hasTamil(false)
                    .build();
        }

        boolean hasTamil = tamilNormalizationService.containsTamilScript(ocrText);
        boolean hasPrintedKeywords = PRINTED_RECEIPT_MARKERS.matcher(ocrText).find();

        // Check if there are Tamil script or Tanglish lines without typical POS header keywords
        if (hasTamil && !hasPrintedKeywords) {
            return ClassificationResult.builder()
                    .documentType(DocumentType.HANDWRITTEN)
                    .confidence(0.80)
                    .reason("Heuristic: Contains Tamil script without printed POS keywords")
                    .hasTamil(true)
                    .build();
        }

        if (hasTamil && hasPrintedKeywords) {
            return ClassificationResult.builder()
                    .documentType(DocumentType.MIXED)
                    .confidence(0.75)
                    .reason("Heuristic: Contains both printed receipt headers and Tamil handwriting")
                    .hasTamil(true)
                    .build();
        }

        // Standard printed receipt detection
        if (hasPrintedKeywords) {
            return ClassificationResult.builder()
                    .documentType(DocumentType.PRINTED)
                    .confidence(0.85)
                    .reason("Heuristic: Contains standard printed POS markers")
                    .hasTamil(false)
                    .build();
        }

        return ClassificationResult.builder()
                .documentType(DocumentType.PRINTED)
                .confidence(0.60)
                .reason("Heuristic default")
                .hasTamil(false)
                .build();
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class ClassificationResult {
        private DocumentType documentType;
        private double confidence;
        private String reason;
        private boolean hasTamil;
    }
}
