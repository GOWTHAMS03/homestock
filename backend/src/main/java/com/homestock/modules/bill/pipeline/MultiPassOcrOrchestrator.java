package com.homestock.modules.bill.pipeline;

import com.homestock.modules.bill.ocr.OcrProvider;
import com.homestock.modules.bill.ocr.OcrResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Coordinates running multiple preprocessing variants through OCR
 * and selects the best result based on extracted text quality.
 *
 * Selection criteria:
 * 1. Number of non-empty lines (more lines = more content extracted)
 * 2. Total character count (more text = better extraction)
 * 3. OCR confidence score
 * 4. Presence of price-like patterns (validates receipt content)
 */
@Service
public class MultiPassOcrOrchestrator {

    private static final Logger log = LoggerFactory.getLogger(MultiPassOcrOrchestrator.class);
    private static final int MAX_OCR_DIMENSION = 1800;

    private final OcrProvider ocrProvider;
    private final ImagePreprocessor imagePreprocessor;
    private final ImageQualityAnalyzer qualityAnalyzer;

    public MultiPassOcrOrchestrator(
            OcrProvider ocrProvider,
            ImagePreprocessor imagePreprocessor,
            ImageQualityAnalyzer qualityAnalyzer
    ) {
        this.ocrProvider = ocrProvider;
        this.imagePreprocessor = imagePreprocessor;
        this.qualityAnalyzer = qualityAnalyzer;
    }

    /**
     * Runs multi-pass OCR on the given image bytes.
     *
     * @param rawImageBytes Raw image bytes
     * @param mimeType      MIME type of the image
     * @return The best OCR result from all preprocessing variants
     */
    public MultiPassOcrResult runMultiPass(byte[] rawImageBytes, String mimeType) {
        long startTime = System.currentTimeMillis();

        // 0. High-res downscaling: mobile cameras take 3000-4000px photos (12MP+).
        // Downscaling to 1800px max dimension preserves 100% text readability while
        // speeding up image analysis, preprocessing, and Windows OCR by 3x-5x.
        byte[] imageBytes = downscaleIfNeeded(rawImageBytes, MAX_OCR_DIMENSION);

        // 1. Image Quality Analysis
        ImageQualityReport qualityReport = qualityAnalyzer.analyze(imageBytes);

        if (!qualityReport.isReadable()) {
            log.warn("Image quality too low (score={}), returning empty result with warning",
                    qualityReport.getQualityScore());
            return MultiPassOcrResult.builder()
                    .bestResult(OcrResult.builder()
                            .fullText("")
                            .lines(new ArrayList<>())
                            .confidence(0.0)
                            .providerName(ocrProvider.getProviderName())
                            .build())
                    .qualityReport(qualityReport)
                    .passCount(0)
                    .selectedVariant("none")
                    .durationMs((int) (System.currentTimeMillis() - startTime))
                    .build();
        }

        // 2. Generate preprocessing variants
        List<ImagePreprocessor.PreprocessedVariant> variants =
                imagePreprocessor.generateVariants(imageBytes, qualityReport);

        // 3. Run OCR on each variant with early exit if first pass is already high-quality
        List<ScoredOcrResult> scoredResults = new ArrayList<>();

        for (ImagePreprocessor.PreprocessedVariant variant : variants) {
            try {
                OcrResult result = ocrProvider.extractText(variant.imageBytes(), mimeType);
                if (result != null && result.getFullText() != null && !result.getFullText().isEmpty()) {
                    result.setPreprocessingVariant(variant.label());
                    double score = scoreOcrResult(result);
                    scoredResults.add(new ScoredOcrResult(variant.label(), result, score));
                    log.debug("OCR variant '{}': {} lines, {} chars, confidence={}, score={}",
                            variant.label(),
                            result.getLines().size(),
                            result.getFullText().length(),
                            result.getConfidence(),
                            score);

                    // EARLY EXIT: If this pass already yielded high-quality text, don't waste 5+ seconds running more passes
                    if (score >= 0.80 && result.getLines().size() >= 5) {
                        log.info("OCR variant '{}' achieved excellent result (score={}, lines={}) — early exiting multi-pass",
                                variant.label(), String.format("%.2f", score), result.getLines().size());
                        break;
                    }
                }
            } catch (Exception e) {
                log.warn("OCR failed for variant '{}': {}", variant.label(), e.getMessage());
            }
        }

        // 4. Select best result
        OcrResult bestResult;
        String selectedVariant;

        if (scoredResults.isEmpty()) {
            // All variants failed — return empty
            bestResult = OcrResult.builder()
                    .fullText("")
                    .lines(new ArrayList<>())
                    .confidence(0.0)
                    .providerName(ocrProvider.getProviderName())
                    .build();
            selectedVariant = "none";
        } else {
            ScoredOcrResult best = scoredResults.stream()
                    .max(Comparator.comparingDouble(ScoredOcrResult::score))
                    .orElse(scoredResults.get(0));
            bestResult = best.result();
            selectedVariant = best.variant();
        }

        int durationMs = (int) (System.currentTimeMillis() - startTime);
        log.info("Multi-pass OCR completed: {} passes, selected='{}', {} lines, confidence={}, duration={}ms",
                scoredResults.size(), selectedVariant,
                bestResult.getLines().size(), bestResult.getConfidence(), durationMs);

        return MultiPassOcrResult.builder()
                .bestResult(bestResult)
                .qualityReport(qualityReport)
                .passCount(scoredResults.size())
                .selectedVariant(selectedVariant)
                .durationMs(durationMs)
                .processedImageBytes(imageBytes)
                .build();
    }

    /**
     * Scores an OCR result for quality comparison between variants.
     * Higher score = better extraction quality.
     */
    private double scoreOcrResult(OcrResult result) {
        String text = result.getFullText();
        if (text == null || text.isEmpty()) return 0.0;

        // Factor 1: Number of non-empty lines
        long lineCount = result.getLines().stream()
                .filter(l -> l != null && !l.trim().isEmpty())
                .count();
        double lineScore = Math.min(1.0, lineCount / 20.0);

        // Factor 2: Total character count (normalize to typical receipt ~500-2000 chars)
        double charScore = Math.min(1.0, text.length() / 1000.0);

        // Factor 3: OCR confidence
        double confScore = result.getConfidence();

        // Factor 4: Presence of price patterns (validates it's actually receipt text)
        long pricePatterns = text.lines()
                .filter(l -> l.matches(".*\\d+\\.\\d{2}.*"))
                .count();
        double priceScore = Math.min(1.0, pricePatterns / 5.0);

        // Factor 5: Presence of receipt keywords
        String upper = text.toUpperCase();
        int keywords = 0;
        for (String kw : new String[]{"TOTAL", "AMOUNT", "QTY", "RATE", "BILL", "DATE", "TAX", "GST", "PRICE"}) {
            if (upper.contains(kw)) keywords++;
        }
        double keywordScore = Math.min(1.0, keywords / 4.0);

        return (lineScore * 0.25) + (charScore * 0.15) + (confScore * 0.20)
                + (priceScore * 0.25) + (keywordScore * 0.15);
    }

    private record ScoredOcrResult(String variant, OcrResult result, double score) {}

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class MultiPassOcrResult {
        private OcrResult bestResult;
        private ImageQualityReport qualityReport;
        private int passCount;
        private String selectedVariant;
        private int durationMs;
        private byte[] processedImageBytes;
    }

    private byte[] downscaleIfNeeded(byte[] imageBytes, int maxDimension) {
        if (imageBytes == null || imageBytes.length < 1000) {
            return imageBytes;
        }
        try {
            BufferedImage img = ImageIO.read(new ByteArrayInputStream(imageBytes));
            if (img == null) return imageBytes;
            int w = img.getWidth();
            int h = img.getHeight();
            if (w <= maxDimension && h <= maxDimension) {
                return imageBytes;
            }
            double scale = Math.min((double) maxDimension / w, (double) maxDimension / h);
            int targetW = Math.max(1, (int) Math.round(w * scale));
            int targetH = Math.max(1, (int) Math.round(h * scale));

            BufferedImage scaled = new BufferedImage(targetW, targetH, BufferedImage.TYPE_INT_RGB);
            Graphics2D g = scaled.createGraphics();
            g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_SPEED);
            g.drawImage(img, 0, 0, targetW, targetH, null);
            g.dispose();

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            ImageIO.write(scaled, "jpg", baos);
            byte[] scaledBytes = baos.toByteArray();
            log.info("Optimized high-res receipt: downscaled from {}x{} to {}x{} (bytes: {} -> {}) for rapid OCR",
                    w, h, targetW, targetH, imageBytes.length, scaledBytes.length);
            return scaledBytes;
        } catch (Exception e) {
            log.warn("Could not downscale image: {}", e.getMessage());
            return imageBytes;
        }
    }
}
