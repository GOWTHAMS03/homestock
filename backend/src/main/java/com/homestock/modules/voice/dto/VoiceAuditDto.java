package com.homestock.modules.voice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VoiceAuditDto {
    private UUID id;
    private Instant timestamp;
    private String recognizedText;
    private String detectedLanguage;
    private String intent;
    private UUID productId;
    private String productName;
    private BigDecimal quantity;
    private String unit;
    private String target;
    private Double intentConfidence;
    private Double productConfidence;
    private String executionStatus;
    private String error;
    private String userCorrection;
    private String idempotencyKey;
    private String commandMode;
}

