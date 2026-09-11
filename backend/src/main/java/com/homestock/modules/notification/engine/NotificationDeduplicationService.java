package com.homestock.modules.notification.engine;

import com.homestock.modules.notification.dto.NotificationCandidate;
import com.homestock.modules.notification.entity.NotificationDeduplication;
import com.homestock.modules.notification.repository.NotificationDeduplicationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

/**
 * NotificationDeduplicationService:
 * Enforces safe idempotency and prevents repetitive alerts using deterministic
 * deduplication keys and cooldown tracking.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationDeduplicationService {

    private final NotificationDeduplicationRepository deduplicationRepository;

    /**
     * Generate a deterministic deduplication key for a candidate.
     */
    public String generateDedupKey(NotificationCandidate candidate) {
        String type = candidate.getType() != null ? candidate.getType().name() : "GENERAL";
        UUID homeId = candidate.getHome() != null ? candidate.getHome().getId() : UUID.randomUUID();
        UUID itemId = candidate.getInventoryItem() != null ? candidate.getInventoryItem().getId() : UUID.nameUUIDFromBytes(new byte[0]);
        String date = LocalDate.now().toString();

        return String.format("%s:%s:%s:%s", type, homeId, itemId, date);
    }

    /**
     * Check whether candidate is a duplicate that should be suppressed.
     * Allows alerts through if stock quantity or status changed significantly.
     */
    @Transactional(readOnly = true)
    public DeduplicationCheck isDuplicate(NotificationCandidate candidate, Duration cooldown) {
        String dedupKey = candidate.getDedupKey() != null ? candidate.getDedupKey() : generateDedupKey(candidate);
        Optional<NotificationDeduplication> existingOpt = deduplicationRepository.findByDedupKey(dedupKey);

        if (existingOpt.isEmpty()) {
            return new DeduplicationCheck(false, dedupKey, "No prior notification recorded for this key");
        }

        NotificationDeduplication existing = existingOpt.get();
        Duration effectiveCooldown = cooldown != null ? cooldown : Duration.ofHours(24);
        Instant now = Instant.now();

        boolean withinCooldown = existing.getLastSentAt().plus(effectiveCooldown).isAfter(now);
        if (!withinCooldown) {
            return new DeduplicationCheck(false, dedupKey, "Cooldown expired (" + effectiveCooldown.toHours() + "h)");
        }

        // Check if quantity changed significantly (e.g. from 2.0 to 0.0)
        BigDecimal currentQty = candidate.getCurrentStock();
        BigDecimal lastQty = existing.getLastQuantity();

        if (currentQty != null && lastQty != null) {
            boolean droppedToZero = currentQty.compareTo(BigDecimal.ZERO) <= 0 && lastQty.compareTo(BigDecimal.ZERO) > 0;
            if (droppedToZero) {
                return new DeduplicationCheck(false, dedupKey, "Stock dropped to zero; urgent alert allowed");
            }
        }

        return new DeduplicationCheck(true, dedupKey, "Duplicate alert suppressed within cooldown window");
    }

    /**
     * Record or update deduplication status upon successful dispatch.
     */
    @Transactional
    public void recordDispatch(NotificationCandidate candidate) {
        String dedupKey = candidate.getDedupKey() != null ? candidate.getDedupKey() : generateDedupKey(candidate);
        UUID homeId = candidate.getHome() != null ? candidate.getHome().getId() : UUID.randomUUID();
        Instant now = Instant.now();

        deduplicationRepository.findByDedupKey(dedupKey).ifPresentOrElse(
                existing -> {
                    existing.setLastSentAt(now);
                    existing.setLastQuantity(candidate.getCurrentStock());
                    existing.setLastStatus(candidate.getType() != null ? candidate.getType().name() : null);
                    deduplicationRepository.save(existing);
                },
                () -> {
                    NotificationDeduplication newDedup = NotificationDeduplication.builder()
                            .dedupKey(dedupKey)
                            .homeId(homeId)
                            .lastSentAt(now)
                            .lastQuantity(candidate.getCurrentStock())
                            .lastStatus(candidate.getType() != null ? candidate.getType().name() : null)
                            .build();
                    deduplicationRepository.save(newDedup);
                }
        );
    }

    public record DeduplicationCheck(
            boolean isDuplicate,
            String dedupKey,
            String reason
    ) {}
}
