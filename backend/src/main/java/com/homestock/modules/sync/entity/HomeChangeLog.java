package com.homestock.modules.sync.entity;

import com.homestock.modules.home.entity.Home;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "home_change_log", indexes = {
        @Index(name = "idx_change_log_home_version", columnList = "home_id, change_version", unique = true),
        @Index(name = "idx_change_log_entity", columnList = "entity_type, entity_id")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HomeChangeLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "home_id", nullable = false)
    private Home home;

    @Column(name = "change_version", nullable = false)
    private Long changeVersion;

    @Column(name = "entity_type", nullable = false, length = 50)
    private String entityType; // INVENTORY_ITEM, STOCK_TRANSACTION, SHOPPING_LIST_ITEM, SHOPPING_LIST, PURCHASE, STORE, CATEGORY

    @Column(name = "entity_id", nullable = false)
    private UUID entityId;

    @Column(name = "operation_type", nullable = false, length = 20)
    private String operationType; // INSERT, UPDATE, DELETE

    @Column(name = "payload", columnDefinition = "TEXT")
    private String payload;

    @Column(name = "operation_id", length = 100)
    private String operationId;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
}

