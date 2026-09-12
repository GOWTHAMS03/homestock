package com.homestock.core.observability;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Component;

/**
 * Metric counters for tracking background, notification, and ML prediction failures.
 */
@Component
public class ApplicationFailureMetrics {

    private final Counter notificationFailureCounter;
    private final Counter mlPredictionFailureCounter;
    private final Counter backgroundJobFailureCounter;

    public ApplicationFailureMetrics(MeterRegistry registry) {
        this.notificationFailureCounter = Counter.builder("homestock.failures")
                .tag("component", "notifications")
                .description("Total notification delivery failures")
                .register(registry);

        this.mlPredictionFailureCounter = Counter.builder("homestock.failures")
                .tag("component", "ml_predictions")
                .description("Total ML prediction calculation failures")
                .register(registry);

        this.backgroundJobFailureCounter = Counter.builder("homestock.failures")
                .tag("component", "background_jobs")
                .description("Total background task and scheduler failures")
                .register(registry);
    }

    public void incrementNotificationFailure() {
        notificationFailureCounter.increment();
    }

    public void incrementMlPredictionFailure() {
        mlPredictionFailureCounter.increment();
    }

    public void incrementBackgroundJobFailure() {
        backgroundJobFailureCounter.increment();
    }
}
