package com.homestock.modules.bill.pipeline;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Analyses the quality of a receipt image before OCR processing.
 * Evaluates resolution, blur, brightness, contrast, and text density
 * to produce a composite quality score and per-factor breakdown.
 *
 * If the image is severely unreadable (score < 0.3), the pipeline
 * should NOT attempt extraction — instead ask the user to retake.
 */
@Service
public class ImageQualityAnalyzer {

    private static final Logger log = LoggerFactory.getLogger(ImageQualityAnalyzer.class);

    private static final int MIN_WIDTH = 300;
    private static final int GOOD_WIDTH = 640;
    private static final int MIN_HEIGHT = 400;
    private static final int GOOD_HEIGHT = 800;

    public ImageQualityReport analyze(byte[] imageBytes) {
        if (imageBytes == null || imageBytes.length < 100) {
            return ImageQualityReport.builder()
                    .qualityScore(BigDecimal.ZERO)
                    .resolution(0)
                    .blurScore(BigDecimal.ZERO)
                    .brightnessScore(BigDecimal.ZERO)
                    .contrastScore(BigDecimal.ZERO)
                    .textDensityScore(BigDecimal.ZERO)
                    .isReadable(false)
                    .message("Image data is empty or too small")
                    .build();
        }

        try {
            BufferedImage image = ImageIO.read(new ByteArrayInputStream(imageBytes));
            if (image == null) {
                return ImageQualityReport.builder()
                        .qualityScore(BigDecimal.valueOf(0.5))
                        .resolution(0)
                        .blurScore(BigDecimal.valueOf(0.5))
                        .brightnessScore(BigDecimal.valueOf(0.5))
                        .contrastScore(BigDecimal.valueOf(0.5))
                        .textDensityScore(BigDecimal.valueOf(0.5))
                        .isReadable(true)
                        .message("Could not decode image for quality analysis; proceeding with OCR")
                        .build();
            }

            int width = image.getWidth();
            int height = image.getHeight();
            int resolution = width * height;

            // 1. Resolution Score
            double resScore = calculateResolutionScore(width, height);

            // 2. Brightness & Contrast Analysis (sample-based for performance)
            double[] brightnessContrast = analyzeBrightnessContrast(image);
            double brightnessScore = brightnessContrast[0];
            double contrastScore = brightnessContrast[1];

            // 3. Blur Detection (Laplacian variance approximation)
            double blurScore = analyzeBlur(image);

            // 4. Text Density (edge density estimation)
            double textDensity = analyzeTextDensity(image);

            // 5. Composite Score (weighted)
            double composite = (resScore * 0.20)
                    + (blurScore * 0.30)
                    + (brightnessScore * 0.15)
                    + (contrastScore * 0.15)
                    + (textDensity * 0.20);

            composite = Math.max(0.0, Math.min(1.0, composite));

            boolean isReadable = composite >= 0.30;
            String message;
            if (composite >= 0.70) {
                message = "Good image quality";
            } else if (composite >= 0.50) {
                message = "Moderate image quality — preprocessing will be applied";
            } else if (composite >= 0.30) {
                message = "Poor image quality — some parts may be difficult to read";
            } else {
                message = "Very poor image quality — please retake the photo with better lighting and focus";
            }

            log.info("Image quality analysis: {}x{}, score={} [res={}, blur={}, bright={}, contrast={}, text={}]",
                    width, height,
                    String.format("%.2f", composite),
                    String.format("%.2f", resScore),
                    String.format("%.2f", blurScore),
                    String.format("%.2f", brightnessScore),
                    String.format("%.2f", contrastScore),
                    String.format("%.2f", textDensity));

            return ImageQualityReport.builder()
                    .qualityScore(BigDecimal.valueOf(composite).setScale(2, RoundingMode.HALF_UP))
                    .resolution(resolution)
                    .width(width)
                    .height(height)
                    .blurScore(BigDecimal.valueOf(blurScore).setScale(2, RoundingMode.HALF_UP))
                    .brightnessScore(BigDecimal.valueOf(brightnessScore).setScale(2, RoundingMode.HALF_UP))
                    .contrastScore(BigDecimal.valueOf(contrastScore).setScale(2, RoundingMode.HALF_UP))
                    .textDensityScore(BigDecimal.valueOf(textDensity).setScale(2, RoundingMode.HALF_UP))
                    .isReadable(isReadable)
                    .message(message)
                    .build();

        } catch (Exception e) {
            log.warn("Image quality analysis failed: {}", e.getMessage());
            // Don't block pipeline on analysis failure — return moderate confidence
            return ImageQualityReport.builder()
                    .qualityScore(BigDecimal.valueOf(0.60))
                    .resolution(0)
                    .blurScore(BigDecimal.valueOf(0.60))
                    .brightnessScore(BigDecimal.valueOf(0.60))
                    .contrastScore(BigDecimal.valueOf(0.60))
                    .textDensityScore(BigDecimal.valueOf(0.60))
                    .isReadable(true)
                    .message("Quality analysis inconclusive; proceeding with OCR")
                    .build();
        }
    }

    private double calculateResolutionScore(int width, int height) {
        if (width < MIN_WIDTH || height < MIN_HEIGHT) return 0.2;
        double wScore = Math.min(1.0, (double) width / GOOD_WIDTH);
        double hScore = Math.min(1.0, (double) height / GOOD_HEIGHT);
        return (wScore + hScore) / 2.0;
    }

    /**
     * Brightness: ideal is ~0.45-0.65 of max (128-166 on 0-255 scale).
     * Too dark or too bright reduces readability.
     * Contrast: standard deviation of pixel intensity — higher is better for text.
     */
    private double[] analyzeBrightnessContrast(BufferedImage image) {
        int width = image.getWidth();
        int height = image.getHeight();
        int sampleStep = Math.max(1, Math.min(width, height) / 100);

        long totalBrightness = 0;
        long totalSquares = 0;
        int count = 0;

        for (int y = 0; y < height; y += sampleStep) {
            for (int x = 0; x < width; x += sampleStep) {
                int rgb = image.getRGB(x, y);
                int r = (rgb >> 16) & 0xFF;
                int g = (rgb >> 8) & 0xFF;
                int b = rgb & 0xFF;
                int gray = (int) (0.299 * r + 0.587 * g + 0.114 * b);
                totalBrightness += gray;
                totalSquares += (long) gray * gray;
                count++;
            }
        }

        if (count == 0) return new double[]{0.5, 0.5};

        double mean = (double) totalBrightness / count;
        double variance = ((double) totalSquares / count) - (mean * mean);
        double stdDev = Math.sqrt(Math.max(0, variance));

        // Brightness: penalize too dark (<80) and too bright (>200)
        double brightnessScore;
        if (mean < 40) brightnessScore = 0.1;
        else if (mean < 80) brightnessScore = 0.3 + 0.4 * ((mean - 40) / 40.0);
        else if (mean <= 200) brightnessScore = 0.7 + 0.3 * (1.0 - Math.abs(mean - 140) / 60.0);
        else brightnessScore = Math.max(0.2, 0.7 - (mean - 200) / 100.0);

        // Contrast: text receipts typically have stdDev 50-90
        double contrastScore;
        if (stdDev < 20) contrastScore = 0.2;
        else if (stdDev < 40) contrastScore = 0.4 + 0.3 * ((stdDev - 20) / 20.0);
        else if (stdDev <= 100) contrastScore = 0.7 + 0.3 * Math.min(1.0, (stdDev - 40) / 50.0);
        else contrastScore = 0.9;

        return new double[]{
                Math.max(0, Math.min(1, brightnessScore)),
                Math.max(0, Math.min(1, contrastScore))
        };
    }

    /**
     * Blur detection via Laplacian variance approximation.
     * Samples pixel intensity differences with neighbors — sharp images have high variance.
     */
    private double analyzeBlur(BufferedImage image) {
        int width = image.getWidth();
        int height = image.getHeight();
        if (width < 3 || height < 3) return 0.5;

        int sampleStep = Math.max(1, Math.min(width, height) / 80);
        long sumLaplacian = 0;
        long sumLapSquares = 0;
        int count = 0;

        for (int y = 1; y < height - 1; y += sampleStep) {
            for (int x = 1; x < width - 1; x += sampleStep) {
                int center = getGray(image, x, y);
                int top = getGray(image, x, y - 1);
                int bottom = getGray(image, x, y + 1);
                int left = getGray(image, x - 1, y);
                int right = getGray(image, x + 1, y);

                int laplacian = Math.abs(4 * center - top - bottom - left - right);
                sumLaplacian += laplacian;
                sumLapSquares += (long) laplacian * laplacian;
                count++;
            }
        }

        if (count == 0) return 0.5;

        double mean = (double) sumLaplacian / count;
        double variance = ((double) sumLapSquares / count) - (mean * mean);

        // Receipts with good focus typically have Laplacian variance > 500
        if (variance < 50) return 0.1;
        if (variance < 200) return 0.3;
        if (variance < 500) return 0.5 + 0.3 * ((variance - 200) / 300.0);
        if (variance < 2000) return 0.8 + 0.2 * Math.min(1.0, (variance - 500) / 1500.0);
        return 1.0;
    }

    /**
     * Text density estimation via simple edge detection.
     * Receipts typically have lots of horizontal text edges.
     */
    private double analyzeTextDensity(BufferedImage image) {
        int width = image.getWidth();
        int height = image.getHeight();
        if (width < 3 || height < 3) return 0.5;

        int sampleStep = Math.max(1, Math.min(width, height) / 80);
        int edgePixels = 0;
        int totalPixels = 0;

        for (int y = 1; y < height - 1; y += sampleStep) {
            for (int x = 1; x < width - 1; x += sampleStep) {
                int gx = Math.abs(getGray(image, x + 1, y) - getGray(image, x - 1, y));
                int gy = Math.abs(getGray(image, x, y + 1) - getGray(image, x, y - 1));
                int gradient = gx + gy;
                if (gradient > 30) edgePixels++;
                totalPixels++;
            }
        }

        if (totalPixels == 0) return 0.5;

        double edgeRatio = (double) edgePixels / totalPixels;

        // Receipts typically have 5-25% edge pixels
        if (edgeRatio < 0.02) return 0.2;
        if (edgeRatio < 0.05) return 0.4;
        if (edgeRatio < 0.25) return 0.7 + 0.3 * Math.min(1.0, (edgeRatio - 0.05) / 0.15);
        return 0.8; // Very busy image — might be noisy
    }

    private int getGray(BufferedImage img, int x, int y) {
        int rgb = img.getRGB(x, y);
        int r = (rgb >> 16) & 0xFF;
        int g = (rgb >> 8) & 0xFF;
        int b = rgb & 0xFF;
        return (int) (0.299 * r + 0.587 * g + 0.114 * b);
    }
}
