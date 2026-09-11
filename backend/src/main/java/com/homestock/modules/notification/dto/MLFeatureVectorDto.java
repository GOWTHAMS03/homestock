package com.homestock.modules.notification.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MLFeatureVectorDto {

    private UUID itemId;
    private UUID userId;
    private UUID homeId;
    private String itemName;

    // Inventory & Consumption Features
    private BigDecimal currentStock;
    private String unit;
    private BigDecimal averageConsumptionPerDay;
    private BigDecimal medianConsumption;
    private BigDecimal consumptionVariance;
    private BigDecimal consumptionVelocity; // recent 7d velocity vs 30d velocity
    private Long daysSinceLastRestock;
    private BigDecimal averageRestockInterval;
    private Double purchaseFrequency;
    private String recentUsageTrend; // ACCELERATING, STABLE, DECELERATING
    private Integer sampleCount;

    // Time & Context Features
    private Integer dayOfWeek; // 1 (Mon) to 7 (Sun)
    private Integer hourOfDay; // 0 to 23

    // User Notification Behavior Features
    private Long notificationCount24h;
    private Long notificationCount1h;
    private Double notificationOpenRate;
    private Double notificationDismissRate;
    private Double userActionRate;
    private Double familyActivityRate;
    private Double previousNotificationSuccessRate;

    // Output predictions
    private BigDecimal predictedDaysRemaining;
    private Double probabilityWithin1Day;
    private Double probabilityWithin3Days;
    private Double probabilityWithin7Days;
    private String modelUsed; // RULE_BASED, STATISTICAL_ML
}
