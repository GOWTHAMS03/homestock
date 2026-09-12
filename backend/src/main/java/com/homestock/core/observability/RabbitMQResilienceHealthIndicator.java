package com.homestock.core.observability;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.stereotype.Component;

import java.net.InetSocketAddress;
import java.net.Socket;

/**
 * Health check indicator for RabbitMQ broker with graceful outbox fallback detection.
 */
@Component("rabbitHealthIndicator")
public class RabbitMQResilienceHealthIndicator implements HealthIndicator {

    @Value("${spring.rabbitmq.host:localhost}")
    private String rabbitHost;

    @Value("${spring.rabbitmq.port:5672}")
    private int rabbitPort;

    @Value("${app.rabbitmq.enabled:false}")
    private boolean rabbitEnabled;

    @Override
    public Health health() {
        if (!rabbitEnabled) {
            return Health.up()
                    .withDetail("rabbitmq", "STANDBY")
                    .withDetail("fallback", "PostgreSQL Transactional Outbox Buffer Active")
                    .build();
        }

        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress(rabbitHost, rabbitPort), 1000);
            return Health.up()
                    .withDetail("rabbitmq", "AVAILABLE")
                    .withDetail("host", rabbitHost)
                    .withDetail("port", rabbitPort)
                    .build();
        } catch (Exception ex) {
            return Health.up()
                    .withDetail("rabbitmq", "DEGRADED")
                    .withDetail("fallback", "PostgreSQL Transactional Outbox Buffer Active")
                    .withDetail("reason", ex.getMessage() != null ? ex.getMessage() : "Broker unreachable")
                    .build();
        }
    }
}
