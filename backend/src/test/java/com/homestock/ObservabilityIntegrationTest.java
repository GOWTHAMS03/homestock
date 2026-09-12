package com.homestock;

import com.homestock.core.observability.ApplicationFailureMetrics;
import com.homestock.core.observability.OfflineSyncMetrics;
import com.homestock.core.observability.RabbitMQResilienceHealthIndicator;
import com.homestock.core.observability.RedisResilienceHealthIndicator;
import io.micrometer.core.instrument.MeterRegistry;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.Status;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("local")
public class ObservabilityIntegrationTest {

    @Autowired
    private OfflineSyncMetrics offlineSyncMetrics;

    @Autowired
    private RedisResilienceHealthIndicator redisHealthIndicator;

    @Autowired
    private RabbitMQResilienceHealthIndicator rabbitMQHealthIndicator;

    @Autowired
    private ApplicationFailureMetrics failureMetrics;

    @Autowired
    private MeterRegistry meterRegistry;

    @Test
    void testOfflineSyncMetrics_Lifecycle() {
        // Record pending events
        offlineSyncMetrics.recordPending(5);
        assertEquals(5.0, meterRegistry.get("homestock.sync.events").tag("state", "pending").counter().count());

        // Simulate syncing
        offlineSyncMetrics.startSyncing();
        assertEquals(1.0, meterRegistry.get("homestock.sync.active.syncing").gauge().value());

        // Complete syncing with success and failure records
        offlineSyncMetrics.recordSuccess(4);
        offlineSyncMetrics.recordFailed(1);
        offlineSyncMetrics.stopSyncing();

        assertEquals(0.0, meterRegistry.get("homestock.sync.active.syncing").gauge().value());
        assertEquals(4.0, meterRegistry.get("homestock.sync.events").tag("state", "success").counter().count());
        assertEquals(1.0, meterRegistry.get("homestock.sync.events").tag("state", "failed").counter().count());

        offlineSyncMetrics.recordDuration(150);
        assertTrue(meterRegistry.get("homestock.sync.duration").timer().count() > 0);
    }

    @Test
    void testHealthIndicators_ReportResilientStatus() {
        // Redis indicator reports UP even when Redis is offline (graceful PostgreSQL fallback active)
        Health redisHealth = redisHealthIndicator.health();
        assertEquals(Status.UP, redisHealth.getStatus());
        assertNotNull(redisHealth.getDetails().get("fallback"));

        // RabbitMQ indicator reports UP even when broker is offline (outbox buffer active)
        Health rabbitHealth = rabbitMQHealthIndicator.health();
        assertEquals(Status.UP, rabbitHealth.getStatus());
        assertNotNull(rabbitHealth.getDetails().get("fallback"));
    }

    @Test
    void testFailureMetrics_CountersIncrement() {
        failureMetrics.incrementNotificationFailure();
        failureMetrics.incrementMlPredictionFailure();
        failureMetrics.incrementBackgroundJobFailure();

        assertTrue(meterRegistry.get("homestock.failures").tag("component", "notifications").counter().count() >= 1.0);
        assertTrue(meterRegistry.get("homestock.failures").tag("component", "ml_predictions").counter().count() >= 1.0);
        assertTrue(meterRegistry.get("homestock.failures").tag("component", "background_jobs").counter().count() >= 1.0);
    }
}
