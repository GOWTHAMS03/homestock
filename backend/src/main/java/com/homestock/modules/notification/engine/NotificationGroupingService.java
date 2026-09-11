package com.homestock.modules.notification.engine;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.notification.dto.NotificationCandidate;
import com.homestock.modules.notification.entity.NotificationDigest;
import com.homestock.modules.notification.entity.NotificationPriority;
import com.homestock.modules.notification.entity.NotificationType;
import com.homestock.modules.notification.repository.NotificationDigestRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

/**
 * NotificationGroupingService:
 * Consolidates multiple concurrent low-stock or restock candidates for a single household
 * into a single cohesive digest alert, preventing inbox clutter and fatigue.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationGroupingService {

    private final NotificationDigestRepository digestRepository;
    private final ObjectMapper objectMapper;

    @Value("${app.notifications.grouping.min-items-threshold:3}")
    private int minItemsThreshold = 3;

    /**
     * Groups a batch of candidates for a household.
     * Bundles restock-eligible candidates into a consolidated digest if threshold is reached.
     */
    @Transactional
    public List<NotificationCandidate> processGrouping(Home home, List<NotificationCandidate> candidates) {
        if (candidates == null || candidates.size() < minItemsThreshold) {
            return candidates != null ? candidates : Collections.emptyList();
        }

        List<NotificationCandidate> result = new ArrayList<>();
        List<NotificationCandidate> restockCandidates = new ArrayList<>();

        for (NotificationCandidate c : candidates) {
            // Never group CRITICAL alerts
            if (c.getBasePriority() == NotificationPriority.CRITICAL) {
                result.add(c);
                continue;
            }

            // Group low-stock and restock suggestions
            if (c.getType() == NotificationType.LOW_STOCK || c.getType() == NotificationType.SMART_RESTOCK_SUGGESTION) {
                restockCandidates.add(c);
            } else {
                result.add(c);
            }
        }

        if (restockCandidates.size() >= minItemsThreshold) {
            NotificationCandidate digestCandidate = createDigestCandidate(home, restockCandidates);
            result.add(digestCandidate);
            log.info("[NotificationGrouping] Grouped {} items into 1 digest for home '{}'",
                    restockCandidates.size(), home.getName());
        } else {
            result.addAll(restockCandidates);
        }

        return result;
    }

    private NotificationCandidate createDigestCandidate(Home home, List<NotificationCandidate> items) {
        List<String> itemNames = items.stream()
                .map(c -> c.getInventoryItem() != null ? c.getInventoryItem().getName() : "Item")
                .distinct()
                .collect(Collectors.toList());

        List<UUID> itemIds = items.stream()
                .map(c -> c.getInventoryItem() != null ? c.getInventoryItem().getId() : null)
                .filter(Objects::nonNull)
                .collect(Collectors.toList());

        // Estimate total shopping cost
        BigDecimal totalCost = BigDecimal.ZERO;
        for (NotificationCandidate c : items) {
            BigDecimal estimatedItemCost = estimateItemCost(c);
            totalCost = totalCost.add(estimatedItemCost);
        }

        String namesSummary = String.join(", ", itemNames);
        String title = String.format("🛒 %d items may run out soon", items.size());
        String body = String.format(
                "%s may need restocking soon. Estimated shopping cost: ₹%s.",
                namesSummary, totalCost.toPlainString()
        );

        // Save persistent digest record
        try {
            NotificationDigest digest = NotificationDigest.builder()
                    .home(home)
                    .title(title)
                    .summaryText(body)
                    .itemCount(items.size())
                    .estimatedTotalCost(totalCost)
                    .itemIdsJson(objectMapper.writeValueAsString(itemIds))
                    .itemNamesJson(objectMapper.writeValueAsString(itemNames))
                    .status("ACTIVE")
                    .build();
            digestRepository.save(digest);
        } catch (Exception e) {
            log.warn("[NotificationGrouping] Failed to persist digest record: {}", e.getMessage());
        }

        // Return unified candidate
        NotificationCandidate first = items.get(0);
        return NotificationCandidate.builder()
                .home(home)
                .recipientUser(first.getRecipientUser())
                .type(NotificationType.SMART_RESTOCK_SUGGESTION)
                .basePriority(NotificationPriority.MEDIUM)
                .proposedTitle(title)
                .proposedBody(body)
                .dedupKey(String.format("DIGEST:%s:%s", home.getId(), Instant.now().toString().substring(0, 10)))
                .currentStock(BigDecimal.valueOf(items.size()))
                .unit("items")
                .predictedDaysRemaining(new BigDecimal("2.5"))
                .probabilityWithin3Days(0.90)
                .confidence("HIGH")
                .candidateTimestamp(Instant.now())
                .payload(Map.of(
                        "isDigest", "true",
                        "itemCount", String.valueOf(items.size()),
                        "estimatedTotalCost", totalCost.toPlainString()
                ))
                .build();
    }

    private BigDecimal estimateItemCost(NotificationCandidate candidate) {
        if (candidate.getDealPrice() != null) {
            return candidate.getDealPrice();
        }
        if (candidate.getInventoryItem() != null) {
            String name = candidate.getInventoryItem().getName().toLowerCase();
            if (name.contains("oil")) return new BigDecimal("155.00");
            if (name.contains("rice")) return new BigDecimal("120.00");
            if (name.contains("atta")) return new BigDecimal("260.00");
            if (name.contains("dal")) return new BigDecimal("170.00");
            if (name.contains("milk")) return new BigDecimal("35.00");
            if (name.contains("soap")) return new BigDecimal("45.00");
        }
        return new BigDecimal("100.00");
    }
}
