package com.homestock.modules.away.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class AwaySummaryResponseDto {

    private UUID summaryId;
    private Boolean isAway;
    private Integer awayDays;
    private LocalDate from;
    private LocalDate to;
    private String greeting;
    private String subtitle;
    private AwaySummaryCounts summary;
    
    @Builder.Default
    private List<AwayPredictionDto> predictions = new ArrayList<>();

    @Builder.Default
    private List<AwayPredictionDto> topPredictions = new ArrayList<>();

    @Builder.Default
    private List<String> knownFamilyEvents = new ArrayList<>();

    private Boolean hasUnreviewedUpdates;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AwaySummaryCounts {
        private Integer importantChanges;
        private Integer predictedLowStock;
        private Integer predictedFinished;
        private Integer expiryRisks;
    }
}
