package com.homestock.modules.notification.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SmartInsightDto {

    private UUID id;
    private String category; // USAGE_TREND, SAVINGS, RESTOCK_HABIT, EXPIRY_PREVENTION
    private String icon;
    private String title;
    private String message;
    private String actionText;
    private String actionRoute;
    private Instant generatedAt;
}
