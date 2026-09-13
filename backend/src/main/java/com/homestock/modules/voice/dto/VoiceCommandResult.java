package com.homestock.modules.voice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VoiceCommandResult {
    private String transcript;
    private VoiceIntent intent;
    private double confidence;
    private VoiceEntities entities;
    private boolean requiresConfirmation;
    private String message;
    @Builder.Default
    private List<DisambiguationOption> disambiguationOptions = new ArrayList<>();

    // Production AI Engine Fields
    @Builder.Default
    private double intentConfidence = 1.0;
    @Builder.Default
    private double productMatchConfidence = 1.0;
    @Builder.Default
    private String detectedLanguage = "EN";
    private String voiceCommandId;
    private String idempotencyKey;
    @Builder.Default
    private String commandMode = "COMMAND";
    private ProductMatchResult productMatch;
    private String executionStatus;
    private boolean needsQuantity;
    private boolean needsProduct;
}
