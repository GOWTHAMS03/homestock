package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Audit record of a rejected candidate product and the exact reason for rejection.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RejectedCandidate {
    private String candidateTitle;
    private String candidateBrand;
    private String provider;
    private RejectionReason rejectionReason;
    private String details;

    public RejectionReason getReason() {
        return rejectionReason;
    }
}
