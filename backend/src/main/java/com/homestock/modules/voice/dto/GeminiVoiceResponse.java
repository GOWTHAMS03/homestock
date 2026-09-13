package com.homestock.modules.voice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GeminiVoiceResponse {
    private String intent;
    private String productText;
    private String productName;
    private BigDecimal quantity;
    private String unit;
    private String target;
    @Builder.Default
    private double intentConfidence = 1.0;
    @Builder.Default
    private String detectedLanguage = "EN";
    private String transcript;
    private boolean needsQuantity;
    private boolean needsProduct;
    private boolean locationRequired;
    private String responseText;
    private String rawJson;
}

