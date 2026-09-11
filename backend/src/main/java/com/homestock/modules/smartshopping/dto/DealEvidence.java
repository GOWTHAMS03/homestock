package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Detailed explainable evidence object attached to verified deals.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DealEvidence {
    private String brandEvidence;
    private String productEvidence;
    private String packSizeEvidence;
    private String priceEvidence;
    private String imageEvidence;
    private int sourceAgreement; // Number of search engines confirming this product
    private Double identityConfidence;
    private Double priceConfidence;
    private Double imageConfidence;
    private List<String> matchedTokens;
}
