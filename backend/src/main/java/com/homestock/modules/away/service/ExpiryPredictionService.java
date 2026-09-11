package com.homestock.modules.away.service;

import com.homestock.modules.away.entity.AwayPredictionType;
import com.homestock.modules.inventory.entity.InventoryItem;
import lombok.Builder;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.Optional;

@Slf4j
@Service
public class ExpiryPredictionService {

    @Data
    @Builder
    public static class ExpiryRiskResult {
        private AwayPredictionType predictionType;
        private boolean hasExpiryRisk;
        private LocalDate expiryDate;
        private long daysRelativeToReturn;
        private Double confidence;
        private String confidenceLabel;
        private String displayTitle;
        private String displaySubtitle;
        private String reason;
    }

    public Optional<ExpiryRiskResult> evaluateExpiryRisk(
            InventoryItem item,
            LocalDate awayStart,
            LocalDate returnDate
    ) {
        if (item.getExpiryDate() == null) {
            return Optional.empty();
        }

        LocalDate expiry = item.getExpiryDate();
        long daysDiff = ChronoUnit.DAYS.between(returnDate, expiry);

        // Scenario 1: Expired during absence (expiryDate <= returnDate)
        if (!expiry.isAfter(returnDate)) {
            return Optional.of(ExpiryRiskResult.builder()
                    .predictionType(AwayPredictionType.MAY_HAVE_EXPIRED)
                    .hasExpiryRisk(true)
                    .expiryDate(expiry)
                    .daysRelativeToReturn(daysDiff)
                    .confidence(0.92)
                    .confidenceLabel("92% confidence")
                    .displayTitle("May have expired")
                    .displaySubtitle("Expiry date fell during your absence. Check before using.")
                    .reason(String.format("Package expiry date was %s", expiry))
                    .build());
        }

        // Scenario 2: Expiring shortly after return (within 3 days of return)
        if (daysDiff <= 3) {
            return Optional.of(ExpiryRiskResult.builder()
                    .predictionType(AwayPredictionType.EXPIRING_SOON)
                    .hasExpiryRisk(true)
                    .expiryDate(expiry)
                    .daysRelativeToReturn(daysDiff)
                    .confidence(0.88)
                    .confidenceLabel("88% confidence")
                    .displayTitle("Expiring very soon")
                    .displaySubtitle(String.format("Expires in %d day(s) on %s. Prioritize usage.", daysDiff, expiry))
                    .reason(String.format("Package expiry date is %s", expiry))
                    .build());
        }

        return Optional.empty();
    }
}
