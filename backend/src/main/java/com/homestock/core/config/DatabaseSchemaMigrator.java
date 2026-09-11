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
            jdbcTemplate.execute("ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check");
            jdbcTemplate.execute("ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_priority_check");
            jdbcTemplate.execute("ALTER TABLE device_tokens DROP CONSTRAINT IF EXISTS device_tokens_device_type_check");
            jdbcTemplate.execute("ALTER TABLE device_tokens ALTER COLUMN device_type DROP NOT NULL");
            jdbcTemplate.execute("ALTER TABLE device_tokens ALTER COLUMN last_used_at DROP NOT NULL");
            jdbcTemplate.execute("ALTER TABLE device_tokens ALTER COLUMN token DROP NOT NULL");
            jdbcTemplate.execute("ALTER TABLE device_tokens DROP CONSTRAINT IF EXISTS uk8se1i37nto56x9252rmrit8ib");
            log.info("[DatabaseSchemaMigrator] Successfully migrated legacy constraints on notifications and device_tokens");
        } catch (Exception e) {
            log.warn("[DatabaseSchemaMigrator] Could not alter table constraints: {}", e.getMessage());
        }
    }
}
