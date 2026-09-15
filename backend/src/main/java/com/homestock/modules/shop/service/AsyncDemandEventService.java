package com.homestock.modules.shop.service;

import com.homestock.modules.deals.entity.UserLocationPreference;
import com.homestock.modules.deals.repository.UserLocationPreferenceRepository;
import com.homestock.modules.shop.entity.CustomerDemandEvent;
import com.homestock.modules.shop.entity.DemandEventType;
import com.homestock.modules.shop.repository.CustomerDemandEventRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

/**
 * Asynchronous, non-blocking demand event recording service.
 * Runs in background threads to guarantee zero customer latency impact.
 * Ensures zero personal customer data is persisted.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AsyncDemandEventService {

    private static final BigDecimal DEFAULT_LAT = BigDecimal.valueOf(12.9716);
    private static final BigDecimal DEFAULT_LON = BigDecimal.valueOf(77.5946);

    private final CustomerDemandEventRepository demandEventRepository;
    private final UserLocationPreferenceRepository userLocationPreferenceRepository;

    /**
     * Records a customer demand event with explicit coordinates.
     */
    @Async
    public void recordEvent(
            DemandEventType eventType,
            String queryText,
            UUID productId,
            String categoryName,
            BigDecimal latitude,
            BigDecimal longitude) {

        if (queryText == null || queryText.isBlank()) return;

        try {
            BigDecimal lat = latitude != null ? latitude : DEFAULT_LAT;
            BigDecimal lon = longitude != null ? longitude : DEFAULT_LON;

            CustomerDemandEvent event = CustomerDemandEvent.builder()
                    .eventType(eventType != null ? eventType : DemandEventType.SEARCH)
                    .queryText(queryText.trim())
                    .normalizedQuery(queryText.trim().toLowerCase())
                    .productId(productId)
                    .categoryName(categoryName)
                    .latitude(lat)
                    .longitude(lon)
                    .createdAt(Instant.now())
                    .build();

            demandEventRepository.save(event);
            log.debug("Recorded demand event: type={}, query='{}'", eventType, queryText.trim());
        } catch (Exception e) {
            log.warn("Failed to asynchronously record demand event: {}", e.getMessage());
        }
    }

    /**
     * Records a demand event by looking up the customer's location context from their preferences.
     * ZERO customer ID is stored in the event table.
     */
    @Async
    public void recordEventForUser(
            DemandEventType eventType,
            String queryText,
            UUID productId,
            String categoryName,
            UUID userId,
            BigDecimal fallbackLat,
            BigDecimal fallbackLon) {

        if (queryText == null || queryText.isBlank()) return;

        try {
            BigDecimal effectiveLat = fallbackLat;
            BigDecimal effectiveLon = fallbackLon;

            if ((effectiveLat == null || effectiveLon == null) && userId != null) {
                UserLocationPreference pref = userLocationPreferenceRepository.findByUserId(userId).orElse(null);
                if (pref != null && pref.getLatitude() != null && pref.getLongitude() != null) {
                    effectiveLat = pref.getLatitude();
                    effectiveLon = pref.getLongitude();
                }
            }

            recordEvent(eventType, queryText, productId, categoryName, effectiveLat, effectiveLon);
        } catch (Exception e) {
            log.warn("Failed to resolve location for demand event: {}", e.getMessage());
        }
    }

    /**
     * Purges demand events older than 90 days for retention management.
     */
    public int purgeExpiredEvents() {
        try {
            Instant cutoff = Instant.now().minus(90, ChronoUnit.DAYS);
            int count = demandEventRepository.purgeOldEvents(cutoff);
            log.info("Purged {} expired customer demand events older than 90 days", count);
            return count;
        } catch (Exception e) {
            log.warn("Failed to purge expired demand events: {}", e.getMessage());
            return 0;
        }
    }
}
