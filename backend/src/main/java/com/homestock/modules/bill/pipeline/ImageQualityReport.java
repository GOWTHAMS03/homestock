package com.homestock.modules.bill.pipeline;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Result of image quality analysis — breakdown of individual quality factors
 * plus a composite score determining whether OCR should proceed.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImageQualityReport {
    private BigDecimal qualityScore;    // 0.00 - 1.00 composite
    private int resolution;             // total pixel count
    private int width;
    private int height;
    private BigDecimal blurScore;       // 0.00 - 1.00 (1 = sharp)
    private BigDecimal brightnessScore; // 0.00 - 1.00 (1 = ideal brightness)
    private BigDecimal contrastScore;   // 0.00 - 1.00 (1 = high contrast)
    private BigDecimal textDensityScore;// 0.00 - 1.00 (1 = good text density)
    private boolean isReadable;         // false if quality < 0.30
    private String message;             // user-facing quality message
}
