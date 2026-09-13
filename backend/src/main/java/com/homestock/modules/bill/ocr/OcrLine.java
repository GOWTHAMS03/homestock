package com.homestock.modules.bill.ocr;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

/**
 * Line-level OCR result with bounding box and constituent words.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OcrLine {
    private String text;
    private double confidence;
    private int y;              // vertical position for layout ordering
    @Builder.Default
    private List<OcrWord> words = new ArrayList<>();
}
