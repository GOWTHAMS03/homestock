package com.homestock.modules.sync.dto;

import lombok.*;

import java.time.Instant;
import java.util.Map;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SyncOperationDto {
    private String operationId;
    private String operationType;
    private String entityType;
    private String entityId;
    private Map<String, Object> payload;
    private Instant createdAt;
}
