package com.homestock.modules.voice.service;

import com.homestock.modules.voice.dto.VoiceIntent;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

@Service
public class VoiceResponseGenerator {

    public String generateSuccessResponse(VoiceIntent intent, String product, BigDecimal quantity, String unit,
                                          BigDecimal remainingStock, String language) {
        String lang = normalizeLanguage(language);
        String qtyStr = (quantity != null) ? formatQuantity(quantity) : "";
        String unitStr = (unit != null) ? unit.toLowerCase() : "";
        String amountStr = (qtyStr + " " + unitStr).trim();
        String prodStr = (product != null && !product.isBlank()) ? product : "item";

        return switch (intent) {
            case ADD_SHOPPING_ITEM -> switch (lang) {
                case "TA" -> (amountStr.isEmpty() ? prodStr : amountStr + " " + prodStr) + "-ஐ shopping list-ல் சேர்த்துவிட்டேன்.";
                case "TANGLISH", "MIXED" -> (amountStr.isEmpty() ? prodStr : amountStr + " " + prodStr) + " shopping list-la add panniten.";
                default -> "Added " + (amountStr.isEmpty() ? prodStr : amountStr + " " + prodStr) + " to your shopping list.";
            };
            case REMOVE_SHOPPING_ITEM -> switch (lang) {
                case "TA" -> prodStr + "-ஐ shopping list-லிருந்து நீக்கிவிட்டேன்.";
                case "TANGLISH", "MIXED" -> prodStr + " shopping list-lerundhu remove panniten.";
                default -> "Removed " + prodStr + " from your shopping list.";
            };
            case CLEAR_SHOPPING_LIST -> switch (lang) {
                case "TA" -> "Shopping list முழுவதும் அழிக்கப்பட்டது.";
                case "TANGLISH", "MIXED" -> "Shopping list full-ah clear panniten.";
                default -> "Shopping list cleared.";
            };
            case ADD_INVENTORY_ITEM, STOCK_IN -> switch (lang) {
                case "TA" -> (amountStr.isEmpty() ? prodStr : amountStr + " " + prodStr) + "-ஐ inventory-ல் சேர்த்துவிட்டேன்.";
                case "TANGLISH", "MIXED" -> (amountStr.isEmpty() ? prodStr : amountStr + " " + prodStr) + " inventory-la add panniten.";
                default -> "Added " + (amountStr.isEmpty() ? prodStr : amountStr + " " + prodStr) + " to your inventory.";
            };
            case STOCK_OUT -> {
                String remStr = (remainingStock != null) ? formatQuantity(remainingStock) + " " + unitStr : "";
                yield switch (lang) {
                    case "TA" -> (amountStr.isEmpty() ? prodStr : amountStr + " " + prodStr) + " பயன்படுத்தப்பட்டது." +
                            (!remStr.isEmpty() ? " மீதமுள்ள இருப்பு: " + remStr + "." : "");
                    case "TANGLISH", "MIXED" -> (amountStr.isEmpty() ? prodStr : amountStr + " " + prodStr) + " use panniyachu." +
                            (!remStr.isEmpty() ? " Meedhi stock: " + remStr + "." : "");
                    default -> "Recorded use of " + (amountStr.isEmpty() ? prodStr : amountStr + " " + prodStr) + "." +
                            (!remStr.isEmpty() ? " Remaining stock: " + remStr + "." : "");
                };
            }
            case GET_ITEM_STATUS -> {
                String stockStr = (remainingStock != null) ? formatQuantity(remainingStock) + " " + unitStr : "0 " + unitStr;
                yield switch (lang) {
                    case "TA" -> prodStr + " இருப்பு " + stockStr + " உள்ளது.";
                    case "TANGLISH", "MIXED" -> prodStr + " stock " + stockStr + " irukku.";
                    default -> "You have " + stockStr + " of " + prodStr + " in stock.";
                };
            }
            default -> "Command processed successfully.";
        };
    }

    public String generateMissingQuantityPrompt(String product, String language) {
        String lang = normalizeLanguage(language);
        String prod = (product != null && !product.isBlank()) ? product : "this item";
        return switch (lang) {
            case "TA" -> "எவ்வளவு " + prod + " சேர்க்க வேண்டும்?";
            case "TANGLISH", "MIXED" -> "Evlo " + prod + " add pannanum?";
            default -> "How much " + prod + " would you like to add?";
        };
    }

    public String generateDisambiguationPrompt(String product, String language) {
        String lang = normalizeLanguage(language);
        String prod = (product != null && !product.isBlank()) ? product : "item";
        return switch (lang) {
            case "TA" -> prod + "-க்கு பல பொருட்கள் உள்ளன. எது வேண்டும் என்பதை தேர்ந்தெடுக்கவும்.";
            case "TANGLISH", "MIXED" -> prod + "-la multiple items irukku. Edhu venum nu select pannunga.";
            default -> "Multiple matches found for " + prod + ". Please select one.";
        };
    }

    public String generateUnclearPrompt(String language) {
        String lang = normalizeLanguage(language);
        return switch (lang) {
            case "TA" -> "சரியாக கேட்கவில்லை. தயவுசெய்து மீண்டும் சொல்லுங்கள்.";
            case "TANGLISH", "MIXED" -> "Puriyala, marubadiyum sollunga.";
            default -> "I couldn't understand that clearly. Please try again.";
        };
    }

    private String normalizeLanguage(String lang) {
        if (lang == null || lang.isBlank()) return "EN";
        String upper = lang.trim().toUpperCase();
        if (upper.contains("TANGLISH")) return "TANGLISH";
        if (upper.contains("MIXED")) return "MIXED";
        if (upper.equals("TA") || upper.startsWith("TAMIL")) return "TA";
        return "EN";
    }

    private String formatQuantity(BigDecimal qty) {
        if (qty == null) return "";
        if (qty.stripTrailingZeros().scale() <= 0) {
            return String.valueOf(qty.longValue());
        }
        return qty.stripTrailingZeros().toPlainString();
    }
}

