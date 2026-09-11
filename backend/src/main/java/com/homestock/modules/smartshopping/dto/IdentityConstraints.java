package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Hard requirement constraints defined for an individual ProductIdentity.
 * Any candidate violating a required constraint is rejected before scoring.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class IdentityConstraints {
    @Builder.Default
    private boolean brandRequired = false;

    @Builder.Default
    private boolean productRequired = true;

    @Builder.Default
    private boolean variantRequired = false;

    @Builder.Default
    private boolean packSizeRequired = false;

    @Builder.Default
    private boolean categoryRequired = true;

    @Builder.Default
    private boolean barcodeRequired = false;

    @Builder.Default
    private double packSizeTolerance = 0.05;
}
