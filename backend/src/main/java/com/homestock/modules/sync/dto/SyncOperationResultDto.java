package com.homestock.modules.sync.dto;

import lombok.*;

import java.util.Map;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SyncOperationResultDto {
    private String operationId;
    private String status; // SYNCED, ALREADY_PROCESSED, CONFLICT, FAILED
    private String errorMessage;
    private Map<String, Object> serverEntity;
}
