package com.homestock.modules.away.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PredictionConfirmRequest {
    @Builder.Default
    private Boolean isConfirmed = true;
}
