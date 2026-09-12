package com.homestock.modules.bill.ocr;

import java.util.List;

/**
 * Pluggable interface for OCR bill scanning.
 * Allows swapping out OCR providers (e.g. Google Cloud Vision, ML Kit, Tesseract)
 * without altering downstream parsing and business logic.
 */
public interface OcrProvider {

    OcrResult extractText(byte[] imageBytes, String mimeType);

    OcrResult extractTextFromImages(List<byte[]> images, List<String> mimeTypes);

    String getProviderName();
}
