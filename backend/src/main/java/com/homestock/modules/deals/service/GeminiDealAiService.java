package com.homestock.modules.deals.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.Getter;
import lombok.Setter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Gemini 3.1 Flash-Lite Deal AI Service.
 * Responsibilities:
 * - Natural language shopping requests (English, Tamil, Tanglish)
 * - Intent extraction & Entity parsing (product, quantity, unit)
 * - Factual deal ranking explanation
 *
 * NON-NEGOTIABLE PRINCIPLES:
 * 1. AI is strictly for NLP and explanation: It NEVER invents prices, shops, stock, or URLs.
 * 2. Deterministic Fallback: If Gemini is offline, slow, or fails, the application falls back immediately to local parsing.
 */
@Service
public class GeminiDealAiService {

    private static final Logger log = LoggerFactory.getLogger(GeminiDealAiService.class);

    @Value("${app.voice.gemini.api-key:${app.bill.ai.gemini.api-key:}}")
    private String apiKey;

    @Value("${app.voice.gemini.model:gemini-flash-lite-latest}")
    private String model;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build();

    private static final String NLP_PROMPT = """
            You are HomeStock Smart Deals AI. You parse grocery queries in English, Tamil, and Tanglish.
            Extract the user intent and entities.
            
            SUPPORTED INTENTS:
            - SEARCH_DEAL: searching for cheapest price for a single product (e.g. "5 kilo ponni arisi cheap ah enga iruku?", "where to buy oil cheap?", "fortune oil price")
            - FIND_BEST_BASKET: finding best deal for whole shopping list (e.g. "best deal for my shopping list", "shopping list items-ku cheap store paaru")
            - NEARBY_SHOP_PRICE: inquiring about prices in nearby shops (e.g. "nearby shop la sugar price paaru", "pakkathula stores la rice evlo?")
            
            RULES:
            1. Normalize productName to standard English grocery name (e.g., "ponni arisi" -> "Ponni Rice", "samayal ennai" -> "Sunflower Oil", "paruppu" -> "Toor Dal", "sakkarai" -> "Sugar").
            2. Extract numeric quantity and standard unit (KG, L, G, ML, PCS).
            3. Return ONLY valid JSON matching this schema:
            {
              "intent": "SEARCH_DEAL|FIND_BEST_BASKET|NEARBY_SHOP_PRICE",
              "productName": "canonical name",
              "quantity": 1.0,
              "unit": "KG|L|G|ML|PCS",
              "brand": "brand if mentioned",
              "locationRequired": true,
              "conversationalReply": "Short polite acknowledgement in user's language (Tamil/Tanglish/English)"
            }
            """;

    @Getter
    @Setter
    public static class ParsedDealIntent {
        private String intent = "SEARCH_DEAL";
        private String productName;
        private BigDecimal quantity;
        private String unit;
        private String brand;
        private boolean locationRequired = true;
        private String conversationalReply;
    }

    /**
     * Parse natural language / voice shopping request using Gemini with deterministic fallback.
     */
    public ParsedDealIntent parseShoppingQuery(String userQuery) {
        if (userQuery == null || userQuery.isBlank()) {
            return buildFallbackIntent(userQuery);
        }

        if (apiKey != null && !apiKey.isBlank() && !apiKey.startsWith("AQ.mock")) {
            try {
                ParsedDealIntent result = callGeminiNlp(userQuery);
                if (result != null && result.getProductName() != null && !result.getProductName().isBlank()) {
                    return result;
                }
            } catch (Exception e) {
                log.warn("[GeminiDealAiService] Gemini NLP call failed ({}), activating deterministic fallback", e.getMessage());
            }
        }

        return buildFallbackIntent(userQuery);
    }

    private ParsedDealIntent callGeminiNlp(String userQuery) throws Exception {
        String url = "https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent?key=" + apiKey;

        Map<String, Object> body = Map.of(
                "contents", List.of(Map.of(
                        "parts", List.of(
                                Map.of("text", NLP_PROMPT),
                                Map.of("text", "User Query: " + userQuery)
                        )
                )),
                "generationConfig", Map.of(
                        "temperature", 0.1,
                        "maxOutputTokens", 512
                )
        );

        String jsonBody = objectMapper.writeValueAsString(body);
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Content-Type", "application/json")
                .timeout(Duration.ofSeconds(5))
                .POST(HttpRequest.BodyPublishers.ofString(jsonBody))
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() != 200) {
            throw new RuntimeException("Gemini returned HTTP " + response.statusCode());
        }

        JsonNode root = objectMapper.readTree(response.body());
        JsonNode candidate = root.path("candidates").path(0).path("content").path("parts").path(0).path("text");
        if (candidate.isMissingNode() || candidate.asText().isBlank()) {
            throw new RuntimeException("Empty response from Gemini");
        }

        String rawText = candidate.asText().trim();
        // Strip markdown code fences if present
        if (rawText.startsWith("```json")) {
            rawText = rawText.substring(7);
        } else if (rawText.startsWith("```")) {
            rawText = rawText.substring(3);
        }
        if (rawText.endsWith("```")) {
            rawText = rawText.substring(0, rawText.length() - 3);
        }

        JsonNode parsed = objectMapper.readTree(rawText.trim());
        ParsedDealIntent intent = new ParsedDealIntent();
        intent.setIntent(parsed.path("intent").asText("SEARCH_DEAL"));
        intent.setProductName(parsed.path("productName").asText(null));
        if (parsed.has("quantity") && !parsed.path("quantity").isNull()) {
            intent.setQuantity(BigDecimal.valueOf(parsed.path("quantity").asDouble()));
        }
        intent.setUnit(parsed.path("unit").asText(null));
        intent.setBrand(parsed.path("brand").asText(null));
        intent.setLocationRequired(parsed.path("locationRequired").asBoolean(true));
        intent.setConversationalReply(parsed.path("conversationalReply").asText("Finding the best deals near you..."));

        return intent;
    }

    /**
     * Deterministic rule-based fallback when Gemini is offline or unavailable.
     */
    public ParsedDealIntent buildFallbackIntent(String query) {
        ParsedDealIntent intent = new ParsedDealIntent();
        if (query == null || query.isBlank()) {
            intent.setProductName("Groceries");
            intent.setConversationalReply("Showing nearby grocery deals.");
            return intent;
        }

        String q = query.toLowerCase().trim();

        // Check for basket / shopping list intent
        if (q.contains("shopping list") || q.contains("basket") || q.contains("list-ku") || q.contains("list la")) {
            intent.setIntent("FIND_BEST_BASKET");
            intent.setProductName("Shopping List");
            intent.setConversationalReply("Finding best deals for your shopping list...");
            return intent;
        }

        // Extract quantity and unit: e.g. "5 kg", "5 kilo", "2 l", "2 litre", "500 g"
        Pattern qtyUnitPattern = Pattern.compile("(\\d+(\\.\\d+)?)\\s*(kg|kilo|kilos|l|litre|litres|liter|g|gram|grams|ml|packet|pcs)");
        Matcher matcher = qtyUnitPattern.matcher(q);
        if (matcher.find()) {
            intent.setQuantity(new BigDecimal(matcher.group(1)));
            String rawUnit = matcher.group(3);
            if (rawUnit.startsWith("k")) intent.setUnit("KG");
            else if (rawUnit.startsWith("l")) intent.setUnit("L");
            else if (rawUnit.startsWith("g")) intent.setUnit("G");
            else if (rawUnit.equals("ml")) intent.setUnit("ML");
            else intent.setUnit("PCS");
        }

        // Multilingual & Tamil/Tanglish dictionary normalization using whole word boundaries
        if (matchesWord(q, "rice", "arisi", "ponni")) {
            intent.setProductName("Ponni Rice");
        } else if (matchesWord(q, "sugar", "sakkarai", "seeni")) {
            intent.setProductName("Sugar");
        } else if (matchesWord(q, "oil", "ennai", "sunflower")) {
            intent.setProductName("Sunflower Oil");
        } else if (matchesWord(q, "dal", "paruppu", "toor", "dhal")) {
            intent.setProductName("Toor Dal");
        } else if (matchesWord(q, "atta", "wheat", "godhumai")) {
            intent.setProductName("Atta");
        } else if (matchesWord(q, "salt", "uppu")) {
            intent.setProductName("Salt");
        } else if (matchesWord(q, "milk", "paal")) {
            intent.setProductName("Milk");
        } else {
            // Clean common filler words
            String cleaned = q.replaceAll("\\b(cheap|cheapest|ah|enga|iruku|irukku|paaru|thedu|find|pannu|nearby|shop|price|evlo)\\b", "")
                    .replaceAll("\\d+(\\.\\d+)?\\s*(kg|kilo|l|litre|g|ml)", "")
                    .trim();
            intent.setProductName(cleaned.isBlank() ? "Groceries" : capitalizeWords(cleaned));
        }

        intent.setIntent(q.contains("nearby") || q.contains("pakkathula") ? "NEARBY_SHOP_PRICE" : "SEARCH_DEAL");
        intent.setConversationalReply("Finding best deals for " + intent.getProductName() + " near you...");

        return intent;
    }

    /**
     * Generate factual, natural deal comparison explanation.
     */
    public String generateDealExplanation(
            String topStoreName,
            BigDecimal singleStoreTotal,
            String splitStoreNames,
            BigDecimal splitTotal,
            BigDecimal potentialSavings,
            Double extraTravelKm
    ) {
        if (potentialSavings != null && potentialSavings.compareTo(BigDecimal.ZERO) > 0 && extraTravelKm != null && extraTravelKm > 0) {
            return String.format(
                    "Best Convenience: Buy everything at %s for ₹%s. Alternatively, buying across %s saves ₹%s, but requires %.1f km extra travel.",
                    topStoreName, singleStoreTotal, splitStoreNames, potentialSavings, extraTravelKm
            );
        } else {
            return String.format(
                    "%s offers the lowest total price at ₹%s for your shopping list with zero additional store stops.",
                    topStoreName, singleStoreTotal
            );
        }
    }

    private String capitalizeWords(String str) {
        String[] words = str.split("\\s+");
        StringBuilder sb = new StringBuilder();
        for (String w : words) {
            if (!w.isBlank()) {
                sb.append(Character.toUpperCase(w.charAt(0))).append(w.substring(1)).append(" ");
            }
        }
        return sb.toString().trim();
    }

    private boolean matchesWord(String text, String... words) {
        for (String w : words) {
            if (Pattern.compile("\\b" + Pattern.quote(w) + "\\b", Pattern.CASE_INSENSITIVE).matcher(text).find()) {
                return true;
            }
        }
        return false;
    }
}
