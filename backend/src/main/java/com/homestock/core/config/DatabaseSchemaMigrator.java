package com.homestock.core.config;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class DatabaseSchemaMigrator {

    private static final Logger log = LoggerFactory.getLogger(DatabaseSchemaMigrator.class);
    private final JdbcTemplate jdbcTemplate;

    @EventListener(ApplicationReadyEvent.class)
    public void migrateSchema() {
        try {
            // Drop legacy check constraints on notifications & device_tokens so newly added enum values can be persisted without DDL conflicts
            jdbcTemplate.execute("ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check");
            jdbcTemplate.execute("ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_priority_check");
            jdbcTemplate.execute("ALTER TABLE device_tokens DROP CONSTRAINT IF EXISTS device_tokens_device_type_check");
            log.info("[DatabaseSchemaMigrator] Successfully dropped legacy enum check constraints on notifications and device_tokens");
        } catch (Exception e) {
            log.warn("[DatabaseSchemaMigrator] Could not alter table constraints: {}", e.getMessage());
        }
    }
}
