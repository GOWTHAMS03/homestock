package com.homestock.modules.deals.service;

import com.homestock.modules.deals.model.DealConfidenceLevel;
import com.homestock.modules.deals.model.FinalPriceResult;
import com.homestock.modules.deals.model.ProductMatchResult;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;

/**
 * Deal Scoring Engine (Phases 10 & 11).
 * Computes composite ranking score and confidence score (0–100).
 * Never ranks a low-confidence product above a highly validated product merely on price.
 */
@Service
public class DealScoringEngine {

    @Value("${deals.scoring.weight.match:0.30}")
    private double weightMatch = 0.30;

    @Value("${deals.scoring.weight.price-advantage:0.20}")
    private double weightPriceAdvantage = 0.20;

    @Value("${deals.scoring.weight.freshness:0.15}")
    private double weightFreshness = 0.15;

    @Value("${deals.scoring.weight.stock:0.10}")
    private double weightStock = 0.10;

    @Value("${deals.scoring.weight.delivery:0.10}")
    private double weightDelivery = 0.10;

    @Value("${deals.scoring.weight.seller-confidence:0.10}")
    private double weightSellerConfidence = 0.10;

    @Value("${deals.scoring.weight.price-confidence:0.05}")
    private double weightPriceConfidence = 0.05;

    public record DealScoreResult(double dealScore, double confidenceScore, DealConfidenceLevel confidenceLevel) {}

    public DealScoreResult scoreDeal(
            ProductMatchResult matchResult,
            FinalPriceResult finalPrice,
            BigDecimal benchmarkHighestPrice,
            Instant lastVerifiedAt,
            boolean inStock,
            Double sellerRating,
            boolean urlVerified
    ) {
        // 1. Product match score (0.0 to 1.0)
        double matchScore = matchResult != null ? matchResult.getMatchScore() : 0.0;

        // 2. Price advantage (0.0 to 1.0): savings relative to highest offer in group
        double priceAdvantage = 0.50;
        if (benchmarkHighestPrice != null && benchmarkHighestPrice.compareTo(BigDecimal.ZERO) > 0 && finalPrice != null) {
            BigDecimal fp = finalPrice.getFinalPrice();
            if (fp.compareTo(benchmarkHighestPrice) <= 0) {
                double diff = benchmarkHighestPrice.subtract(fp).doubleValue();
                priceAdvantage = Math.min(1.0, 0.50 + (diff / benchmarkHighestPrice.doubleValue()));
            } else {
                priceAdvantage = 0.30;
            }
        }

        // 3. Freshness score (0.0 to 1.0)
        double freshnessScore = 1.0;
        if (lastVerifiedAt != null) {
            long ageSeconds = Math.max(0, Duration.between(lastVerifiedAt, Instant.now()).getSeconds());
            if (ageSeconds < 60) freshnessScore = 1.0;
            else if (ageSeconds < 300) freshnessScore = 0.90;
            else if (ageSeconds < 900) freshnessScore = 0.75;
            else if (ageSeconds < 1800) freshnessScore = 0.50;
            else freshnessScore = 0.20;
        }

        // 4. Stock score
        double stockScore = inStock ? 1.0 : 0.0;

        // 5. Delivery score
        double deliveryScore = (finalPrice != null && !finalPrice.isDeliveryChargesMayApply()) ? 1.0 : 0.80;

        // 6. Seller confidence score
        double sellerScore = sellerRating != null ? Math.min(1.0, sellerRating / 5.0) : 0.85;

        // 7. Price confidence
        double priceConf = finalPrice != null ? finalPrice.getPriceConfidence() : 0.80;

        // URL verification bonus / penalty
        double urlScore = urlVerified ? 1.0 : 0.40;

        // Composite Deal Score (0.0 to 1.0)
        double compositeScore = (matchScore * weightMatch)
                + (priceAdvantage * weightPriceAdvantage)
                + (freshnessScore * weightFreshness)
                + (stockScore * weightStock)
                + (deliveryScore * weightDelivery)
                + (sellerScore * weightSellerConfidence)
                + (priceConf * weightPriceConfidence);

        // Confidence Score (0 to 100)
        // Heavily influenced by match accuracy, stock certainty, and URL verification
        double rawConfidence = (matchScore * 0.40 + stockScore * 0.20 + urlScore * 0.20 + freshnessScore * 0.10 + priceConf * 0.10) * 100.0;
        double confidence = Math.min(100.0, Math.max(0.0, rawConfidence));

        DealConfidenceLevel level = DealConfidenceLevel.fromScore(confidence);

        return new DealScoreResult(compositeScore, confidence, level);
    }
}
