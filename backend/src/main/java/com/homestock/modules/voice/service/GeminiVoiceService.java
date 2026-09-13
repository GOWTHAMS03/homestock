package com.homestock.modules.voice.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.homestock.modules.voice.config.VoiceProperties;
import com.homestock.modules.voice.dto.GeminiVoiceResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.*;

@Slf4j
@Service
public class GeminiVoiceService {

    private final VoiceProperties voiceProperties;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    @Value("${app.voice.gemini.api-key:${app.bill.ai.gemini.api-key:}}")
    private String apiKey;

    @Value("${app.voice.gemini.model:gemini-flash-lite-latest}")
    private String model;

    private static final String SYSTEM_PROMPT = """
            You are Homie, an intelligent grocery and household inventory voice assistant for HomeStock.
            You understand spoken voice commands in English, Tamil, Tanglish (Tamil words written or spoken in English phonetics), and Mixed language (code-switching).

            Your task is to understand the user's intent, extract key entities, and produce a STRICT JSON response.

            SUPPORTED INTENTS:
            - ADD_TO_SHOPPING_LIST: Adding an item or grocery to buy (e.g., "2 kilo rice shopping list la add pannu", "add milk to shopping list", "sugar add pannu", "2 packet biscuit vaanganum")
            - REMOVE_FROM_SHOPPING_LIST: Removing item from shopping list (e.g., "shopping list la irukura oil remove pannu", "delete milk from list")
            - UPDATE_SHOPPING_LIST_ITEM: Changing quantity or details of shopping item (e.g., "change rice to 5 kg in shopping list")
            - CLEAR_SHOPPING_LIST: Clearing entire shopping list (e.g., "clear shopping list", "list full-ah delete pannu")
            - ADD_TO_INVENTORY: Purchased items or adding stock to home pantry (e.g., "naan 5 kilo rice vangiten", "1 litre oil inventory la add pannu", "bought 2 packets milk")
            - UPDATE_INVENTORY: Adjusting inventory stock count (e.g., "rice stock 5 kg nu maathu")
            - REMOVE_FROM_INVENTORY: Removing item completely from inventory (e.g., "remove oil from inventory")
            - CONSUME_INVENTORY: Used or consumed stock (e.g., "2 packet milk use panniten", "consumed 500g sugar", "1 bottle oil theendhuruchu")
            - GET_INVENTORY: Inquiring current stock / balance (e.g., "inventory la rice stock evlo irukku?", "do we have sugar?", "oil irukka?")
            - GET_SHOPPING_LIST: Viewing shopping list (e.g., "shopping list kaatu", "what is on my shopping list?")
            - SEARCH_PRODUCT: Searching for a product or price (e.g., "search fortune oil", "rice thedu")
            - GET_PRODUCT_DETAILS: Detailed info on product (e.g., "tell me about tata salt")
            - UNKNOWN: Unrelated or unintelligible speech

            RULES:
            1. Transcribe the audio faithfully as spoken into 'transcript'.
            2. Detect the spoken language: 'EN', 'TA' (Tamil script), 'TANGLISH' (Tamil in English), or 'MIXED'.
            3. Extract 'productText' (exact words spoken for the product) and 'productName' (canonical English grocery name).
            4. Extract 'quantity' as a number (e.g., 2, 0.5, 1.5). Handle number words in Tamil (rendu=2, moonu=3, arai=0.5, onnara=1.5).
            5. Extract canonical 'unit': 'KG', 'G', 'L', 'ML', 'PCS', 'PACKET', 'BOTTLE', 'BOX', 'CAN', 'DOZEN'. If not specified, set null.
            6. Determine 'target': 'SHOPPING_LIST' or 'INVENTORY'.
               - If user says "add pannu" without specifying list or inventory:
                 - "vangiten" / "bought" / "vanthuruchu" -> INVENTORY
                 - "vaanganum" / "need to buy" / "add pannu" (default) -> SHOPPING_LIST
            7. For ADD_TO_SHOPPING_LIST, if quantity was NOT mentioned, default quantity: 1.0, needsQuantity: false (e.g., "add sugar to shopping list" -> 1.0 sugar). For inventory CONSUME_INVENTORY, STOCK_IN or UPDATE_INVENTORY without quantity, set needsQuantity: true, quantity: null.
            8. If the speech is ambiguous about the product name, set needsProduct: true.
            9. Provide a concise, polite 'responseText' matching the user's spoken language:
               - English: "Added 2 kg Rice to shopping list." or "How much Rice would you like to add?"
               - Tamil: "2 கிலோ அரிசியை shopping list-ல் சேர்த்துவிட்டேன்." or "எவ்வளவு அரிசி சேர்க்க வேண்டும்?"
               - Tanglish: "2 kilo Rice shopping list-la add panniten." or "Evlo Rice add pannanum?"
            10. Return ONLY a valid JSON object matching the schema below. No markdown fences. No preamble.

            SCHEMA:
            {
              "transcript": "exact spoken words",
              "detectedLanguage": "EN|TA|TANGLISH|MIXED",
              "intent": "INTENT_STRING",
              "productText": "spoken product words",
              "productName": "Canonical Name",
              "quantity": 1.0,
              "unit": "KG|G|L|ML|PCS|PACKET|BOTTLE|BOX|CAN|DOZEN",
              "target": "SHOPPING_LIST|INVENTORY|NONE",
              "intentConfidence": 0.98,
              "needsQuantity": false,
              "needsProduct": false,
              "responseText": "conversational response"
            }
            """;

    public GeminiVoiceService(VoiceProperties voiceProperties, ObjectMapper objectMapper) {
        this.voiceProperties = voiceProperties;
        this.objectMapper = objectMapper;
        this.httpClient = HttpClient.newBuilder()
                .version(HttpClient.Version.HTTP_2)
                .connectTimeout(Duration.ofSeconds(15))
                .build();
    }

    public GeminiVoiceResponse processAudio(byte[] audioBytes, String mimeType) throws Exception {
        if (audioBytes == null || audioBytes.length == 0) {
            throw new IllegalArgumentException("Audio data cannot be empty");
        }

        String safeMime = normalizeAudioMimeType(mimeType);
        String prompt = "Listen carefully to this audio command and produce the required JSON command.";
        String jsonResponse = callGeminiApi(audioBytes, safeMime, prompt);
        return parseResponse(jsonResponse);
    }

    public GeminiVoiceResponse processText(String transcript) throws Exception {
        if (transcript == null || transcript.isBlank()) {
            throw new IllegalArgumentException("Transcript cannot be blank");
        }

        String prompt = "Parse this text command and produce the required JSON command: \"" + transcript + "\"";
        String jsonResponse = callGeminiApi(null, null, prompt);
        return parseResponse(jsonResponse);
    }

    private String callGeminiApi(byte[] audioBytes, String mimeType, String userPrompt) throws Exception {
        String effectiveApiKey = (apiKey != null && !apiKey.isBlank())
                ? apiKey
                : voiceProperties.getGemini().getApiKey();

        if (effectiveApiKey == null || effectiveApiKey.isBlank()) {
            throw new IllegalStateException("Gemini API key is not configured for voice processing");
        }

        String effectiveModel = (model != null && !model.isBlank())
                ? model
                : voiceProperties.getGemini().getModel();

        String url = String.format(
                "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s",
                effectiveModel, effectiveApiKey
        );

        List<Map<String, Object>> parts = new ArrayList<>();

        // If audio is present, add as multimodal inlineData
        if (audioBytes != null && audioBytes.length > 0) {
            String base64Data = Base64.getEncoder().encodeToString(audioBytes);
            Map<String, Object> inlineData = new LinkedHashMap<>();
            inlineData.put("mimeType", mimeType != null ? mimeType : "audio/wav");
            inlineData.put("data", base64Data);

            Map<String, Object> audioPart = new LinkedHashMap<>();
            audioPart.put("inlineData", inlineData);
            parts.add(audioPart);
        }

        // Add text prompt
        Map<String, Object> textPart = new LinkedHashMap<>();
        textPart.put("text", userPrompt);
        parts.add(textPart);

        Map<String, Object> contentMap = new LinkedHashMap<>();
        contentMap.put("parts", parts);

        // Generation config
        Map<String, Object> genConfig = new LinkedHashMap<>();
        genConfig.put("temperature", voiceProperties.getGemini().getTemperature());
        genConfig.put("maxOutputTokens", voiceProperties.getGemini().getMaxOutputTokens());
        genConfig.put("responseMimeType", "application/json");

        Map<String, Object> requestPayload = new LinkedHashMap<>();
        // Add system instruction
        Map<String, Object> systemPart = Map.of("text", SYSTEM_PROMPT);
        requestPayload.put("system_instruction", Map.of("parts", List.of(systemPart)));
        requestPayload.put("contents", List.of(contentMap));
        requestPayload.put("generationConfig", genConfig);

        String requestBody = objectMapper.writeValueAsString(requestPayload);

        int timeoutSeconds = voiceProperties.getGemini().getTimeoutSeconds();
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Content-Type", "application/json")
                .timeout(Duration.ofSeconds(timeoutSeconds > 0 ? timeoutSeconds : 30))
                .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                .build();

        log.debug("Sending audio/text request to Gemini Voice AI: model={}", effectiveModel);
        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() != 200) {
            log.error("Gemini Voice API failed with status {}: {}", response.statusCode(),
                    response.body().substring(0, Math.min(500, response.body().length())));
            throw new RuntimeException("Gemini Voice API request failed with status: " + response.statusCode());
        }

        JsonNode root = objectMapper.readTree(response.body());
        JsonNode candidates = root.path("candidates");
        if (candidates.isArray() && !candidates.isEmpty()) {
            JsonNode candidateParts = candidates.get(0).path("content").path("parts");
            if (candidateParts.isArray() && !candidateParts.isEmpty()) {
                String text = candidateParts.get(0).path("text").asText("").trim();
                if (text.startsWith("```json")) text = text.substring(7);
                if (text.startsWith("```")) text = text.substring(3);
                if (text.endsWith("```")) text = text.substring(0, text.length() - 3);
                return text.trim();
            }
        }

        throw new RuntimeException("Empty or malformed candidate response from Gemini Voice API");
    }

    private GeminiVoiceResponse parseResponse(String json) {
        try {
            JsonNode root = objectMapper.readTree(json);

            String intent = root.path("intent").asText("UNKNOWN");
            String productText = root.path("productText").isNull() ? null : root.path("productText").asText(null);
            String productName = root.path("productName").isNull() ? null : root.path("productName").asText(null);

            BigDecimal quantity = null;
            if (root.hasNonNull("quantity")) {
                quantity = BigDecimal.valueOf(root.path("quantity").asDouble());
            }

            String unit = root.path("unit").isNull() ? null : root.path("unit").asText(null);
            if (unit != null && (unit.equalsIgnoreCase("null") || unit.isBlank())) {
                unit = null;
            }

            String target = root.path("target").asText("NONE");
            double intentConfidence = root.path("intentConfidence").asDouble(1.0);
            String detectedLanguage = root.path("detectedLanguage").asText("EN");
            String transcript = root.path("transcript").asText("");
            boolean needsQuantity = root.path("needsQuantity").asBoolean(false);
            boolean needsProduct = root.path("needsProduct").asBoolean(false);
            String responseText = root.path("responseText").asText("");

            return GeminiVoiceResponse.builder()
                    .intent(intent)
                    .productText(productText)
                    .productName(productName)
                    .quantity(quantity)
                    .unit(unit != null ? unit.toUpperCase() : null)
                    .target(target)
                    .intentConfidence(intentConfidence)
                    .detectedLanguage(detectedLanguage)
                    .transcript(transcript)
                    .needsQuantity(needsQuantity)
                    .needsProduct(needsProduct)
                    .responseText(responseText)
                    .rawJson(json)
                    .build();

        } catch (Exception e) {
            log.error("Failed to parse Gemini Voice JSON response: {}", json, e);
            return GeminiVoiceResponse.builder()
                    .intent("UNKNOWN")
                    .transcript(json)
                    .intentConfidence(0.0)
                    .responseText("Sorry, I could not understand the voice command.")
                    .rawJson(json)
                    .build();
        }
    }

    private String normalizeAudioMimeType(String mimeType) {
        if (mimeType == null || mimeType.isBlank() || "application/octet-stream".equalsIgnoreCase(mimeType)) {
            return "audio/mp4";
        }
        String lower = mimeType.toLowerCase();
        if (lower.contains("mp4") || lower.contains("m4a") || lower.contains("aac")) return "audio/mp4";
        if (lower.contains("wav")) return "audio/wav";
        if (lower.contains("webm")) return "audio/webm";
        if (lower.contains("mpeg") || lower.contains("mp3")) return "audio/mp3";
        if (lower.contains("ogg")) return "audio/ogg";
        if (lower.contains("flac")) return "audio/flac";
        return mimeType;
    }
}

