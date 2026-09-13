package com.homestock.modules.bill.pipeline;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.*;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.List;

/**
 * Adaptive image preprocessing pipeline for receipt images.
 * Generates multiple preprocessing variants and returns all of them
 * so the OCR orchestrator can select the best result.
 *
 * Operations: grayscale, contrast enhancement, adaptive thresholding,
 * sharpening, denoising. Pure Java — no external image libraries needed.
 */
@Service
public class ImagePreprocessor {

    private static final Logger log = LoggerFactory.getLogger(ImagePreprocessor.class);

    /**
     * Generates multiple preprocessed variants of the input image.
     * Returns a list of byte arrays (JPEG encoded), each representing
     * a different preprocessing strategy.
     */
    public List<PreprocessedVariant> generateVariants(byte[] imageBytes, ImageQualityReport qualityReport) {
        List<PreprocessedVariant> variants = new ArrayList<>();

        // Variant 0: Original image (always include)
        variants.add(new PreprocessedVariant("original", imageBytes));

        // If image quality is already high (>= 0.80), original image is all that's needed!
        if (qualityReport != null && qualityReport.getQualityScore().doubleValue() >= 0.80) {
            log.info("Image quality is high ({}) — using original image without additional preprocessing variants",
                    String.format("%.2f", qualityReport.getQualityScore().doubleValue()));
            return variants;
        }

        try {
            BufferedImage original = ImageIO.read(new ByteArrayInputStream(imageBytes));
            if (original == null) {
                return variants;
            }

            // Variant 1: Grayscale + Contrast Enhanced
            BufferedImage gray = toGrayscale(original);
            BufferedImage enhanced = enhanceContrast(gray);
            byte[] enhancedBytes = toJpegBytes(enhanced);
            if (enhancedBytes != null) {
                variants.add(new PreprocessedVariant("grayscale_enhanced", enhancedBytes));
            }

            // Only generate more variants for moderate/poor quality images
            if (qualityReport != null && qualityReport.getQualityScore().doubleValue() < 0.70) {

                // Variant 2: Grayscale + Thresholded (Otsu-like)
                BufferedImage thresholded = adaptiveThreshold(gray);
                byte[] threshBytes = toJpegBytes(thresholded);
                if (threshBytes != null) {
                    variants.add(new PreprocessedVariant("thresholded", threshBytes));
                }

                // Variant 3: Sharpened + Contrast
                BufferedImage sharpened = sharpen(enhanced);
                byte[] sharpBytes = toJpegBytes(sharpened);
                if (sharpBytes != null) {
                    variants.add(new PreprocessedVariant("sharpened_enhanced", sharpBytes));
                }
            }

            log.info("Generated {} preprocessing variants for image (quality={})",
                    variants.size(),
                    String.format("%.2f", qualityReport != null ? qualityReport.getQualityScore().doubleValue() : 0.0));

        } catch (Exception e) {
            log.warn("Image preprocessing failed: {}", e.getMessage());
        }

        return variants;
    }

    private BufferedImage toGrayscale(BufferedImage src) {
        BufferedImage gray = new BufferedImage(src.getWidth(), src.getHeight(), BufferedImage.TYPE_BYTE_GRAY);
        Graphics2D g = gray.createGraphics();
        g.drawImage(src, 0, 0, null);
        g.dispose();
        return gray;
    }

    /**
     * Histogram stretching — maps the darkest/lightest pixels to full 0-255 range.
     */
    private BufferedImage enhanceContrast(BufferedImage src) {
        int width = src.getWidth();
        int height = src.getHeight();

        // Find min/max pixel values
        int min = 255, max = 0;
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int gray = src.getRGB(x, y) & 0xFF;
                if (gray < min) min = gray;
                if (gray > max) max = gray;
            }
        }

        if (max <= min) return src;

        // Clip the extremes to reduce noise influence
        int clipMin = min + (max - min) / 50;
        int clipMax = max - (max - min) / 50;
        if (clipMax <= clipMin) { clipMin = min; clipMax = max; }

        double scale = 255.0 / (clipMax - clipMin);
        BufferedImage result = new BufferedImage(width, height, src.getType());

        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int gray = src.getRGB(x, y) & 0xFF;
                int stretched = (int) Math.max(0, Math.min(255, (gray - clipMin) * scale));
                int rgb = (stretched << 16) | (stretched << 8) | stretched;
                result.setRGB(x, y, 0xFF000000 | rgb);
            }
        }

        return result;
    }

    /**
     * Adaptive thresholding using a block-based mean approach.
     * Similar to Otsu's method but using local neighborhoods.
     */
    private BufferedImage adaptiveThreshold(BufferedImage gray) {
        int width = gray.getWidth();
        int height = gray.getHeight();
        int blockSize = Math.max(15, Math.min(width, height) / 20);
        if (blockSize % 2 == 0) blockSize++;

        BufferedImage result = new BufferedImage(width, height, BufferedImage.TYPE_BYTE_GRAY);
        int halfBlock = blockSize / 2;

        // Build integral image for fast local mean computation
        long[][] integral = new long[height + 1][width + 1];
        for (int y = 0; y < height; y++) {
            long rowSum = 0;
            for (int x = 0; x < width; x++) {
                rowSum += gray.getRGB(x, y) & 0xFF;
                integral[y + 1][x + 1] = integral[y][x + 1] + rowSum;
            }
        }

        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int x1 = Math.max(0, x - halfBlock);
                int y1 = Math.max(0, y - halfBlock);
                int x2 = Math.min(width - 1, x + halfBlock);
                int y2 = Math.min(height - 1, y + halfBlock);

                int area = (x2 - x1 + 1) * (y2 - y1 + 1);
                long sum = integral[y2 + 1][x2 + 1] - integral[y1][x2 + 1] - integral[y2 + 1][x1] + integral[y1][x1];
                double localMean = (double) sum / area;

                int pixel = gray.getRGB(x, y) & 0xFF;
                int output = (pixel > localMean - 10) ? 255 : 0;
                result.setRGB(x, y, 0xFF000000 | (output << 16) | (output << 8) | output);
            }
        }

        return result;
    }

    /**
     * Unsharp mask sharpening — enhances text edges.
     */
    private BufferedImage sharpen(BufferedImage src) {
        float[] kernel = {
                0, -0.5f, 0,
                -0.5f, 3.0f, -0.5f,
                0, -0.5f, 0
        };
        BufferedImageOp op = new ConvolveOp(
                new Kernel(3, 3, kernel),
                ConvolveOp.EDGE_NO_OP, null
        );
        BufferedImage result = new BufferedImage(src.getWidth(), src.getHeight(), src.getType());
        op.filter(src, result);
        return result;
    }

    private byte[] toJpegBytes(BufferedImage image) {
        try {
            // Convert to RGB if needed (JPEG doesn't support alpha)
            BufferedImage rgb = image;
            if (image.getType() != BufferedImage.TYPE_3BYTE_BGR &&
                image.getType() != BufferedImage.TYPE_BYTE_GRAY &&
                image.getType() != BufferedImage.TYPE_INT_RGB) {
                rgb = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_3BYTE_BGR);
                Graphics2D g = rgb.createGraphics();
                g.drawImage(image, 0, 0, null);
                g.dispose();
            }
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            ImageIO.write(rgb, "jpg", baos);
            return baos.toByteArray();
        } catch (Exception e) {
            log.warn("Failed to encode preprocessed image: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Represents one preprocessing variant with a descriptive label.
     */
    public record PreprocessedVariant(String label, byte[] imageBytes) {}
}
