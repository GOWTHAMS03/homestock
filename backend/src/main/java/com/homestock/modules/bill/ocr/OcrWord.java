package com.homestock.modules.bill.ocr;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Word-level OCR result with bounding box coordinates.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OcrWord {
    private String text;
    private double confidence;
    private int x;      // top-left x
    private int y;      // top-left y
    private int width;
    private int height;
}
