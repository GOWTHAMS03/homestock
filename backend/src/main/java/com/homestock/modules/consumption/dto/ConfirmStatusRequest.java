package com.homestock.modules.consumption.dto;

import com.homestock.modules.consumption.entity.QuantityStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConfirmStatusRequest {
    private QuantityStatus status; // ALMOST_FULL, MORE_THAN_HALF, ABOUT_HALF, LESS_THAN_HALF, ALMOST_EMPTY, EMPTY
    private String action; // STILL_HAVE_ENOUGH, ADD_TO_SHOPPING
}
