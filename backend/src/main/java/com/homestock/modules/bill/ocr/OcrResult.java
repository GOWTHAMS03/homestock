package com.homestock.modules.bill.ocr;

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
public class OcrResult {
    private String fullText;
    @Builder.Default
    private List<String> lines = new ArrayList<>();
    @Builder.Default
    private double confidence = 0.95;
    private String providerName;
}
