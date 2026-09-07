package com.homestock.modules.sync.entity;

import com.homestock.core.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "processed_operations",
       indexes = {
           @Index(name = "idx_processed_op_id", columnList = "operation_id", unique = true),
           @Index(name = "idx_processed_home_id", columnList = "home_id")
       })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProcessedOperation extends BaseEntity {

    @Column(name = "operation_id", nullable = false, unique = true, length = 64)
    private String operationId;

    @Column(name = "home_id", nullable = false)
    private UUID homeId;

    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "operation_type", nullable = false, length = 50)
    private String operationType;

    @Column(name = "entity_type", nullable = false, length = 50)
    private String entityType;

    @Column(name = "entity_id", length = 64)
    private String entityId;

    @Column(name = "status", nullable = false, length = 30)
    private String status; // SYNCED, ALREADY_PROCESSED, FAILED, CONFLICT

    @Column(name = "error_message", length = 1000)
    private String errorMessage;

    @Column(name = "processed_at", nullable = false)
    private Instant processedAt;
}
