package com.homestock.modules.voice.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class TranscriptionResult {
    private String transcript;
    private String language;
    private double confidence;
    private long processingTimeMs;
}
