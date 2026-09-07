package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Response after recording an affiliate click.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AffiliateClickResponse {
    private String affiliateUrl;
    private String provider;
    private String providerProductId;
}
