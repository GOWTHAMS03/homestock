package com.homestock.core.observability;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.stereotype.Component;

import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Production-grade Micrometer metrics for offline synchronization lifecycle.
 * Tracks transitions: PENDING -> SYNCING -> SUCCESS / FAILED.
 */
@Component
public class OfflineSyncMetrics {

    private final Counter syncPendingCounter;
    private final Counter syncSuccessCounter;
    private final Counter syncFailedCounter;
    private final AtomicInteger activeSyncingGauge;
    private final Timer syncDurationTimer;

    public OfflineSyncMetrics(MeterRegistry registry) {
        this.syncPendingCounter = Counter.builder("homestock.sync.events")
                .tag("state", "pending")
                .description("Total offline sync events queued for processing")
                .register(registry);

        this.syncSuccessCounter = Counter.builder("homestock.sync.events")
                .tag("state", "success")
                .description("Total offline sync events successfully applied")
                .register(registry);

        this.syncFailedCounter = Counter.builder("homestock.sync.events")
                .tag("state", "failed")
                .description("Total offline sync events that failed during processing")
                .register(registry);

        this.activeSyncingGauge = registry.gauge("homestock.sync.active.syncing", new AtomicInteger(0));

        this.syncDurationTimer = Timer.builder("homestock.sync.duration")
                .description("Latency of offline sync batch execution")
                .publishPercentiles(0.5, 0.95, 0.99)
                .register(registry);
    }

    public void recordPending(int count) {
        syncPendingCounter.increment(count);
    }

    public void startSyncing() {
        if (activeSyncingGauge != null) {
            activeSyncingGauge.incrementAndGet();
        }
    }

    public void stopSyncing() {
        if (activeSyncingGauge != null && activeSyncingGauge.get() > 0) {
            activeSyncingGauge.decrementAndGet();
        }
    }

    public void recordSuccess(int count) {
        syncSuccessCounter.increment(count);
    }

    public void recordFailed(int count) {
        syncFailedCounter.increment(count);
    }

    public void recordDuration(long durationMs) {
        syncDurationTimer.record(durationMs, TimeUnit.MILLISECONDS);
    }
}
