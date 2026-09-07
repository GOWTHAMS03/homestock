package com.homestock.modules.voice.service;

import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.voice.dto.*;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class VoiceCommandParser {

    private static final Logger log = LoggerFactory.getLogger(VoiceCommandParser.class);

    private final UnitNormalizationService unitNormalizer;
    private final NumberNormalizationService numberNormalizer;
    private final TamilTanglishNormalizer tamilTanglishNormalizer;
    private final ProductMatcher productMatcher;

    public VoiceCommandResult parse(UUID homeId, String rawTranscript) {
        if (rawTranscript == null || rawTranscript.isBlank()) {
            return VoiceCommandResult.builder()
                    .transcript("")
                    .intent(VoiceIntent.UNKNOWN)
                    .confidence(0.0)
                    .message("No speech recognized. Please speak again.")
                    .build();
        }

        String transcript = rawTranscript.trim();
        String lower = transcript.toLowerCase();

        // 1. Navigation intents
        if (matchesAny(lower, "open shopping list", "go to shopping list", "shopping list open", "shopping list kaatu")) {
            return buildResult(transcript, VoiceIntent.OPEN_SHOPPING_LIST, 0.98, null, false, "Opening your shopping list.");
        }
        if (matchesAny(lower, "open inventory", "go to inventory", "open pantry", "inventory open", "inventory kaatu")) {
            return buildResult(transcript, VoiceIntent.OPEN_INVENTORY, 0.98, null, false, "Opening your inventory.");
        }
        if (matchesAny(lower, "open analytics", "show analytics", "spending", "expenses", "selavu")) {
            return buildResult(transcript, VoiceIntent.OPEN_ANALYTICS, 0.95, null, false, "Opening your spending analytics.");
        }

        // 2. Query intents
        if (matchesAny(lower, "what's running low", "what is running low", "running low", "low stock", "kammiya irukku", "theera pogudhu")) {
            return buildResult(transcript, VoiceIntent.GET_LOW_STOCK_ITEMS, 0.95, null, false, "Checking low stock items...");
        }
        if (matchesAny(lower, "what is expiring", "expiring items", "expiring soon", "expire aaga pogudhu", "expiry date")) {
            return buildResult(transcript, VoiceIntent.GET_EXPIRING_ITEMS, 0.95, null, false, "Checking items expiring soon...");
        }
        if (matchesAny(lower, "what is in my shopping list", "what's in shopping list", "show shopping list", "shopping list la enna irukku", "enna vaanganum")) {
            return buildResult(transcript, VoiceIntent.GET_SHOPPING_LIST, 0.95, null, false, "Fetching your shopping list...");
        }

        // 3. Smart Price Check
        if (matchesAny(lower, "cheapest price", "where can i buy", "find cheapest", "price comparison", "best offer", "enga kammiya kedaikkum", "cheapest")) {
            VoiceEntities entities = extractEntities(lower);
            return buildResult(transcript, VoiceIntent.SMART_PRICE_CHECK, 0.92, entities, false,
                    "Comparing prices for " + entities.getItemName() + " across online stores...");
        }

        // 4. Status Check for an item ("Do we have rice at home?", "Rice irukka?", "Rice stock evlo irukku?")
        if (matchesAny(lower, "do we have", "at home", "is there", "irukka", "irukkaa", "evlo irukku", "how much", "check stock", "stock check")) {
            VoiceEntities entities = extractEntities(lower);
            resolveItemMatching(homeId, entities);
            String name = entities.getMatchedInventoryItemName() != null ? entities.getMatchedInventoryItemName() : entities.getItemName();
            return buildResult(transcript, VoiceIntent.GET_ITEM_STATUS, 0.93, entities, false,
                    "Checking availability of " + name + " in your household...");
        }

        // 5. Remove from Shopping List ("Remove sugar from shopping list", "Sugar shopping list la irundhu remove pannu")
        if (matchesAny(lower, "remove from shopping", "delete from shopping", "remove pannu", "thooku", "delete pannu", "vendam")
                && matchesAny(lower, "shopping", "list")) {
            VoiceEntities entities = extractEntities(lower);
            return buildResult(transcript, VoiceIntent.REMOVE_SHOPPING_ITEM, 0.92, entities, true,
                    "Remove " + entities.getItemName() + " from your shopping list?");
        }

        // 6. Complete / Bought Shopping Item ("Rice bought", "Milk vaangiyachu", "Mark rice as bought")
        if (matchesAny(lower, "bought", "vaangiyachu", "eduthachu", "mark as bought", "purchased already")) {
            VoiceEntities entities = extractEntities(lower);
            resolveItemMatching(homeId, entities);
            String name = entities.getMatchedInventoryItemName() != null ? entities.getMatchedInventoryItemName() : entities.getItemName();
            return buildResult(transcript, VoiceIntent.COMPLETE_SHOPPING_ITEM, 0.92, entities, true,
                    "Mark " + name + " as bought and restock inventory?");
        }

        // 7. Stock Out / Consumption ("Used 500 ml oil", "500 ml oil use panniten", "theendhuduchu", "kaali aayiduchu", "consumed")
        if (matchesAny(lower, "used", "consumed", "use panniten", "theendhuduchu", "theendhiduchu", "theerndhuduchu", "theerndhiduchu", "theernthuduchu", "theernthiduchu", "theerndhadhu", "kaali aayiduchu", "finish aayiduchu", "mudinjuruchu", "stock out")) {
            VoiceEntities entities = extractEntities(lower);
            resolveItemMatching(homeId, entities);

            ProductMatcher.MatchResult match = productMatcher.matchProduct(homeId, entities.getItemName());
            if (match.isAmbiguous()) {
                List<DisambiguationOption> options = productMatcher.createOptionsFromItems(match.ambiguousMatches);
                return VoiceCommandResult.builder()
                        .transcript(transcript)
                        .intent(VoiceIntent.STOCK_OUT)
                        .confidence(0.75)
                        .entities(entities)
                        .requiresConfirmation(true)
                        .message("Which " + entities.getItemName() + " did you use?")
                        .disambiguationOptions(options)
                        .build();
            }

            String qtyStr = entities.getQuantity() != null ? (entities.getQuantity() + " " + entities.getUnit()) : "some";
            String itemName = entities.getMatchedInventoryItemName() != null ? entities.getMatchedInventoryItemName() : entities.getItemName();
            return buildResult(transcript, VoiceIntent.STOCK_OUT, 0.93, entities, true,
                    "Deduct " + qtyStr + " " + itemName + " from inventory?");
        }

        // 8. Stock In / Direct Addition ("Bought 2 litre oil", "Added 5 kg rice", "stock in")
        if (matchesAny(lower, "bought", "purchased", "stock in", "restock", "vanthurukku", "vaanginen")
                && !matchesAny(lower, "shopping list")) {
            VoiceEntities entities = extractEntities(lower);
            resolveItemMatching(homeId, entities);
            String qtyStr = entities.getQuantity() != null ? (entities.getQuantity() + " " + entities.getUnit()) : "1 PCS";
            String itemName = entities.getMatchedInventoryItemName() != null ? entities.getMatchedInventoryItemName() : entities.getItemName();
            return buildResult(transcript, VoiceIntent.STOCK_IN, 0.92, entities, true,
                    "Add " + qtyStr + " " + itemName + " to inventory stock?");
        }

        // 9. Update Stock ("Rice stock 5 kg", "Cooking oil quantity 500 ml ah update pannu")
        if (matchesAny(lower, "stock", "quantity", "alavu") && matchesAny(lower, "update", "set", "mathu", "irukku")) {
            VoiceEntities entities = extractEntities(lower);
            resolveItemMatching(homeId, entities);
            String qtyStr = entities.getQuantity() != null ? (entities.getQuantity() + " " + entities.getUnit()) : "5";
            String itemName = entities.getMatchedInventoryItemName() != null ? entities.getMatchedInventoryItemName() : entities.getItemName();

            // Provide options for Set vs Add ambiguity
            List<DisambiguationOption> disambiguation = new ArrayList<>();
            disambiguation.add(DisambiguationOption.builder()
                    .id("SET")
                    .label("Set stock to " + qtyStr)
                    .subLabel("Replaces current recorded quantity")
                    .action("SET_STOCK")
                    .build());
            disambiguation.add(DisambiguationOption.builder()
                    .id("ADD")
                    .label("Add " + qtyStr + " more")
                    .subLabel("Increases current recorded quantity")
                    .action("ADD_STOCK")
                    .build());

            return VoiceCommandResult.builder()
                    .transcript(transcript)
                    .intent(VoiceIntent.UPDATE_STOCK)
                    .confidence(0.88)
                    .entities(entities)
                    .requiresConfirmation(true)
                    .message("Update stock for " + itemName + " to " + qtyStr + " or add it?")
                    .disambiguationOptions(disambiguation)
                    .build();
        }

        // 10. Search Inventory ("Show rice", "Find oil", "Search for ...")
        if (matchesAny(lower, "show", "find", "search", "thedu", "engae") && !matchesAny(lower, "shopping list", "add")) {
            VoiceEntities entities = extractEntities(lower);
            return buildResult(transcript, VoiceIntent.SEARCH_INVENTORY, 0.90, entities, false,
                    "Searching inventory for " + entities.getItemName() + "...");
        }

        // 11. Add to Shopping List (Default and most frequent action)
        // Matches "Add ... to shopping list", "... shopping list la add pannu", "shopping list la ... podu", "buy ..."
        VoiceEntities entities = extractEntities(lower);
        resolveItemMatching(homeId, entities);

        ProductMatcher.MatchResult match = productMatcher.matchProduct(homeId, entities.getItemName());
        if (match.isAmbiguous()) {
            List<DisambiguationOption> options = productMatcher.createOptionsFromItems(match.ambiguousMatches);
            return VoiceCommandResult.builder()
                    .transcript(transcript)
                    .intent(VoiceIntent.ADD_SHOPPING_ITEM)
                    .confidence(0.85)
                    .entities(entities)
                    .requiresConfirmation(true)
                    .message("Which " + entities.getItemName() + " would you like to add?")
                    .disambiguationOptions(options)
                    .build();
        }

        String qtyDisplay = entities.getQuantity() != null ? (entities.getQuantity().stripTrailingZeros().toPlainString() + " " + entities.getUnit()) : "";
        String msg = qtyDisplay.isEmpty()
                ? "Add " + entities.getItemName() + " to shopping list?"
                : "Add " + qtyDisplay + " " + entities.getItemName() + " to shopping list?";

        return buildResult(transcript, VoiceIntent.ADD_SHOPPING_ITEM, 0.95, entities, true, msg);
    }

    private void resolveItemMatching(UUID homeId, VoiceEntities entities) {
        if (homeId != null && entities.getItemName() != null) {
            ProductMatcher.MatchResult match = productMatcher.matchProduct(homeId, entities.getItemName());
            if (match.exactMatch != null) {
                entities.setMatchedInventoryItemId(match.exactMatch.getId());
                entities.setMatchedInventoryItemName(match.exactMatch.getName());
                if (entities.getUnit() == null || entities.getUnit().equals("PCS")) {
                    entities.setUnit(match.exactMatch.getUnit());
                }
            }
        }
    }

    /**
     * Extracts quantity, unit, price, brand, and clean item name from transcript.
     */
    VoiceEntities extractEntities(String text) {
        String clean = text.replaceAll("[.,;:!?]", " ").trim();

        BigDecimal quantity = numberNormalizer.extractFirstNumber(clean);
        String unit = "PCS";

        // Extract Unit
        String[] words = clean.split("\\s+");
        for (String w : words) {
            if (unitNormalizer.isUnit(w)) {
                unit = unitNormalizer.normalize(w);
                break;
            }
        }

        // Default 1 if quantity is null
        if (quantity == null) {
            quantity = BigDecimal.ONE;
        }

        // Extract Price (e.g. "50 rupees", "rs 100", "₹ 200", "50 rooba")
        BigDecimal price = null;
        Pattern pricePattern = Pattern.compile("(?i)(?:rs\\.?|rupees?|rooba|ரூபாய்|₹)\\s*(\\d+(?:\\.\\d+)?)|(\\d+(?:\\.\\d+)?)\\s*(?:rs\\.?|rupees?|rooba|ரூபாய்|₹)");
        Matcher priceMatcher = pricePattern.matcher(clean);
        if (priceMatcher.find()) {
            String pStr = priceMatcher.group(1) != null ? priceMatcher.group(1) : priceMatcher.group(2);
            try {
                price = new BigDecimal(pStr);
            } catch (Exception ignored) {}
        }

        // Extract Brand (known brands)
        String brand = null;
        String[] knownBrands = {"Aashirvaad", "Fortune", "Tata", "Gold Winner", "Amul", "Nandini", "Heritage", "Sunfeast", "Britannia", "Parle"};
        for (String b : knownBrands) {
            if (clean.toLowerCase().contains(b.toLowerCase())) {
                brand = b;
                break;
            }
        }

        // Extract Item Name by filtering out common stop words, units, numbers, and command phrases
        String itemCandidate = clean;
        // Strip common voice command markers
        itemCandidate = itemCandidate.replaceAll("(?i)\\b(add|put|buy|remove|delete|used|stock|in|out|quantity|shopping|list|la|podu|pannu|irukku|irukka|theendhuduchu|vaanganum|eduthachu|bought|update|set|to|from|for|me|please|show|find|search|cheapest|price|where)\\b", " ");
        // Strip units
        itemCandidate = itemCandidate.replaceAll("(?i)\\b(kg|kgs|kilo|litre|litres|liter|liters|litru|ml|g|gm|packet|packets|pack|packs|bottle|bottles|can|box|pieces?|pcs)\\b", " ");
        // Strip digits
        itemCandidate = itemCandidate.replaceAll("\\b\\d+(\\.\\d+)?\\b", " ");
        // Strip number words
        itemCandidate = itemCandidate.replaceAll("(?i)\\b(one|two|three|four|five|six|seven|eight|nine|ten|onnu|oru|rendu|moonu|naalu|anju|aaru|ezhu|ettu|ombadhu|pathu|half|arai|kaal)\\b", " ");

        itemCandidate = itemCandidate.trim().replaceAll("\\s+", " ");
        if (itemCandidate.isBlank()) {
            itemCandidate = "Item";
        }

        String normalizedName = tamilTanglishNormalizer.normalizeItemName(itemCandidate);

        return VoiceEntities.builder()
                .itemName(normalizedName)
                .quantity(quantity)
                .unit(unit)
                .brand(brand)
                .price(price)
                .build();
    }

    private boolean matchesAny(String input, String... phrases) {
        for (String p : phrases) {
            if (input.contains(p)) {
                return true;
            }
        }
        return false;
    }

    private VoiceCommandResult buildResult(String transcript, VoiceIntent intent, double confidence, VoiceEntities entities, boolean requiresConfirmation, String message) {
        return VoiceCommandResult.builder()
                .transcript(transcript)
                .intent(intent)
                .confidence(confidence)
                .entities(entities != null ? entities : VoiceEntities.builder().build())
                .requiresConfirmation(requiresConfirmation)
                .message(message)
                .disambiguationOptions(new ArrayList<>())
                .build();
    }
}
