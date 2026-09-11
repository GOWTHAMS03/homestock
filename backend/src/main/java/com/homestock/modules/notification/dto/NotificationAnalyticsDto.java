package com.homestock.modules.notification.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationAnalyticsDto {

    private long totalGenerated;
    private long totalSent;
    private long totalSuppressed;
    private long totalGrouped;
    private long totalOpened;
    private long totalDismissed;
    private long totalActionsTaken;

    private double actionRate;        // totalActionsTaken / totalSent
    private double openRate;          // totalOpened / totalSent
    private double dismissRate;       // totalDismissed / totalSent
    private double suppressionRate;   // totalSuppressed / totalGenerated

    private BigDecimal averageFatigueScore;
    private Map<String, Long> decisionsByType;
    private Map<String, Long> eventsByChannel;
}
