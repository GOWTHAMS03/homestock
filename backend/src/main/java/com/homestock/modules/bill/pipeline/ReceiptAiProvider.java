package com.homestock.modules.bill.pipeline;

/**
 * Pluggable interface for AI-powered receipt understanding.
 * Implementations convert raw OCR text into structured receipt data
 * with per-field confidence scores.
 *
 * Providers must NEVER hallucinate missing values.
 * If a field cannot be confidently determined, return null with needsReview=true.
 */
public interface ReceiptAiProvider {

    /**
     * Extract structured receipt data from OCR text.
     *
     * @param ocrText The raw OCR text extracted from the receipt
     * @param ocrLines Individual lines from OCR
     * @return Structured extraction result with confidence scores
     */
    ReceiptExtractionResult extract(String ocrText, java.util.List<String> ocrLines);

    /**
     * Extract structured receipt data using multimodal vision (image + OCR text)
     * for maximum accuracy.
     *
     * @param imageBytes  Receipt image binary (optional)
     * @param mimeType    MIME type of the image (e.g. image/jpeg)
     * @param ocrText     Raw OCR text extracted as auxiliary reference
     * @param ocrLines    Individual lines from OCR
     * @return Structured extraction result with confidence scores
     */
    default ReceiptExtractionResult extractWithImage(byte[] imageBytes, String mimeType, String ocrText, java.util.List<String> ocrLines) {
        return extract(ocrText, ocrLines);
    }

    /**
     * @return Name of this AI provider (e.g., "gemini", "openai")
     */
    String getProviderName();

    /**
     * @return Whether this provider is currently available/configured
     */
    boolean isAvailable();
}
