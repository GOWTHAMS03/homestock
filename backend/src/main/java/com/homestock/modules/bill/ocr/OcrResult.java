package com.homestock.modules.bill.ocr;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OcrResult {
    private String fullText;
    @Builder.Default
    private List<String> lines = new ArrayList<>();
    @Builder.Default
    private double confidence = 0.95;
    private String providerName;

    // Extended fields for multi-stage pipeline
    @Builder.Default
    private List<OcrWord> words = new ArrayList<>();
    @Builder.Default
    private List<OcrLine> detectedLines = new ArrayList<>();
    private String detectedLanguage;
    @Builder.Default
    private Map<String, Double> fieldConfidences = new HashMap<>();
    private String preprocessingVariant; // which variant produced this result
}

