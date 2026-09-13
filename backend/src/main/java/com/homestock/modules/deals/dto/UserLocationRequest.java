package com.homestock.modules.deals.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;

/**
 * Production-grade DTO for client location context submissions.
 * Validates coordinate limits, accuracy bounds, and timestamp freshness.
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserLocationRequest {

    @NotNull(message = "Latitude is required")
    @DecimalMin(value = "-90.0", message = "Latitude must be >= -90.0")
    @DecimalMax(value = "90.0", message = "Latitude must be <= 90.0")
    private BigDecimal latitude;

    @NotNull(message = "Longitude is required")
    @DecimalMin(value = "-180.0", message = "Longitude must be >= -180.0")
    @DecimalMax(value = "180.0", message = "Longitude must be <= 180.0")
    private BigDecimal longitude;

    @DecimalMin(value = "0.0", message = "Accuracy must be >= 0.0 meters")
    @DecimalMax(value = "10000.0", message = "Accuracy must be <= 10000.0 meters")
    private Double accuracyMeters;

    private Instant timestamp;

    /**
     * Verify timestamp is within valid boundaries (not from future, not ancient).
     */
    public boolean isValidTimestamp() {
        if (timestamp == null) return true;
        Instant now = Instant.now();
        // Allow up to 5 minutes future drift, reject updates older than 24 hours
        return !timestamp.isAfter(now.plus(Duration.ofMinutes(5))) &&
               !timestamp.isBefore(now.minus(Duration.ofHours(24)));
    }

    /**
     * Privacy-safe masked representation for log records (no exact coordinates logged).
     */
    public String getMaskedLocation() {
        String latStr = latitude != null ? latitude.toPlainString() : "null";
        String lonStr = longitude != null ? longitude.toPlainString() : "null";

        String maskedLat = latStr.contains(".") ? latStr.substring(0, latStr.indexOf('.') + 3) + "***" : latStr;
        String maskedLon = lonStr.contains(".") ? lonStr.substring(0, lonStr.indexOf('.') + 3) + "***" : lonStr;

        return String.format("(lat=%s, lon=%s, accuracy=%.1fm)",
                maskedLat, maskedLon, accuracyMeters != null ? accuracyMeters : 0.0);
    }
}

