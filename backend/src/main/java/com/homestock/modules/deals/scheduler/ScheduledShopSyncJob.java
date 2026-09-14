package com.homestock.modules.deals.scheduler;

import com.homestock.modules.deals.entity.ShopAreaGrid;
import com.homestock.modules.deals.repository.ShopAreaGridRepository;
import com.homestock.modules.deals.service.ShopDiscoverySyncService;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

/**
 * Scheduled background job that re-synchronizes pending and stale geographic grids.
 * Throttles background requests to adhere to public OpenStreetMap server policies.
 */
@Component
@RequiredArgsConstructor
public class ScheduledShopSyncJob {

    private static final Logger log = LoggerFactory.getLogger(ScheduledShopSyncJob.class);

    private final ShopAreaGridRepository gridRepository;
    private final ShopDiscoverySyncService syncService;

    @Value("${app.deals.shop-sync.enabled:true}")
    private boolean enabled;

    @Value("${app.deals.shop-sync.stale-threshold-hours:12}")
    private int staleThresholdHours = 12;

    @Value("${app.deals.shop-sync.max-batch-size:3}")
    private int maxBatchSize = 3;

    @Scheduled(fixedDelayString = "${app.deals.shop-sync.fixed-delay-ms:900000}", initialDelay = 60000)
    public void synchronizeStaleGrids() {
        if (!enabled) {
            return;
        }

        Instant staleThreshold = Instant.now().minus(Duration.ofHours(staleThresholdHours));
        List<ShopAreaGrid> candidates = gridRepository.findStaleOrPendingGrids(
                staleThreshold, PageRequest.of(0, maxBatchSize));

        if (candidates.isEmpty()) {
            return;
        }

        log.info("[SCHEDULED_SHOP_SYNC] Found {} geographic grids eligible for background refresh", candidates.size());

        for (ShopAreaGrid grid : candidates) {
            try {
                if (syncService.isSyncInProgress(grid.getGridKey())) {
                    continue;
                }

                syncService.syncGrid(
                        grid.getGridKey(),
                        grid.getCenterLat().doubleValue(),
                        grid.getCenterLon().doubleValue(),
                        grid.getRadiusMeters()
                );

                // Polite throttle: 2 seconds between batch items to respect public Overpass mirrors
                Thread.sleep(2000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            } catch (Exception e) {
                log.warn("[SCHEDULED_SHOP_SYNC] Failed refreshing grid {}: {}", grid.getGridKey(), e.getMessage());
            }
        }
    }
}
