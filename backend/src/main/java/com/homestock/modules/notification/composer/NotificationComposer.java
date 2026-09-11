package com.homestock.modules.notification.composer;

import com.homestock.modules.notification.dto.NotificationCandidate;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

/**
 * NotificationComposer:
 * Generates human, concise, action-oriented notification copy.
 * Emphasizes "What happened?", "Why does it matter?", and "What can I do?".
 */
@Component
public class NotificationComposer {

    public ComposedNotification compose(NotificationCandidate candidate) {
        String itemName = candidate.getInventoryItem() != null ? candidate.getInventoryItem().getName() : "Item";
        String icon = resolveProductIcon(itemName);

        // 1. Deal Enhanced Restock Template
        if (candidate.isDealAvailable() && candidate.getPotentialSavings() != null &&
                candidate.getPotentialSavings().compareTo(BigDecimal.ZERO) > 0) {
            String title = String.format("%s %s may run out soon", icon, itemName);
            String body = String.format(
                    "A better price is available now: ₹%s instead of ₹%s (Save ₹%s on %s).",
                    candidate.getDealPrice(), candidate.getRegularPrice(), candidate.getPotentialSavings(),
                    candidate.getDealStore() != null ? candidate.getDealStore() : "Online"
            );
            return new ComposedNotification(title, body, "View Deal", "/shopping/deals");
        }

        // 2. Type-Specific Templates
        if (candidate.getType() != null) {
            switch (candidate.getType().canonical()) {
                case OUT_OF_STOCK: {
                    String title = String.format("🚨 %s is out of stock", itemName);
                    String body = "Your household has run out of " + itemName + ". Add it to the shared shopping list now.";
                    return new ComposedNotification(title, body, "Add to List", "/shopping-list");
                }

                case LOW_STOCK:
                case SMART_RESTOCK_SUGGESTION: {
                    BigDecimal days = candidate.getPredictedDaysRemaining();
                    String daysStr = (days != null && days.compareTo(BigDecimal.ZERO) > 0) ?
                            String.format("~%.0f days", days.doubleValue()) : "soon";

                    String title = String.format("%s %s may run out in %s", icon, itemName, daysStr);
                    String body = String.format(
                            "Based on recent household usage, %s will likely run out in %s. You usually restock around this time.",
                            itemName, daysStr
                    );
                    return new ComposedNotification(title, body, "Add to List", "/shopping-list");
                }

                case EXPIRY_REMINDER: {
                    String title = String.format("⏳ %s is expiring soon", itemName);
                    String body = String.format(
                            "Check your inventory to use %s before it expires.", itemName
                    );
                    return new ComposedNotification(title, body, "Check Inventory", "/inventory");
                }

                case FAMILY_ACTIVITY:
                case PURCHASE_RECORDED:
                case STOCK_UPDATED: {
                    String actor = candidate.getTriggerUser() != null ? candidate.getTriggerUser().getFullName() : "A family member";
                    String title = String.format("👨‍👩‍👧 %s updated %s", actor, itemName);
                    String body = String.format("%s was restocked today. Household inventory is up to date.", itemName);
                    return new ComposedNotification(title, body, "View Inventory", "/inventory");
                }

                case SHOPPING_LIST_UPDATE: {
                    String actor = candidate.getTriggerUser() != null ? candidate.getTriggerUser().getFullName() : "A family member";
                    String title = "🛒 Shared Shopping List updated";
                    String body = actor + " updated items on your household shopping list.";
                    return new ComposedNotification(title, body, "Review List", "/shopping-list");
                }

                case WEEKLY_INSIGHT: {
                    String title = "💡 Weekly Household Insight";
                    String body = candidate.getProposedBody() != null ? candidate.getProposedBody() :
                            "Review your household consumption trends and savings this week.";
                    return new ComposedNotification(title, body, "View Insights", "/analytics");
                }

                default:
                    break;
            }
        }

        // Fallback
        String title = candidate.getProposedTitle() != null ? candidate.getProposedTitle() : "HomeStock Update";
        String body = candidate.getProposedBody() != null ? candidate.getProposedBody() : "Your inventory has been updated.";
        return new ComposedNotification(title, body, "Open HomeStock", "/home");
    }

    private String resolveProductIcon(String itemName) {
        if (itemName == null) return "📦";
        String lower = itemName.toLowerCase();
        if (lower.contains("oil") || lower.contains("ghee")) return "🛢️";
        if (lower.contains("rice") || lower.contains("grain")) return "🌾";
        if (lower.contains("milk") || lower.contains("curd") || lower.contains("dairy")) return "🥛";
        if (lower.contains("atta") || lower.contains("flour")) return "🌾";
        if (lower.contains("dal") || lower.contains("lentil")) return "🥣";
        if (lower.contains("soap") || lower.contains("shampoo")) return "🧼";
        if (lower.contains("toothpaste") || lower.contains("brush")) return "🪥";
        if (lower.contains("detergent") || lower.contains("dishwash")) return "🫧";
        if (lower.contains("tea") || lower.contains("coffee")) return "☕";
        if (lower.contains("biscuit") || lower.contains("snack")) return "🍪";
        return "📦";
    }

    public record ComposedNotification(
            String title,
            String body,
            String actionLabel,
            String actionRoute
    ) {}
}
