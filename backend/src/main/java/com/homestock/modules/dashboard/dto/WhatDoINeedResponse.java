package com.homestock.modules.dashboard.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WhatDoINeedResponse {
    private List<RecommendationItemDto> urgent;
    private List<RecommendationItemDto> soon;
    private List<RecommendationItemDto> optional;
}
