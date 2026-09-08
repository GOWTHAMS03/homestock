package com.homestock.modules.smartshopping.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Request to record an affiliate link click.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AffiliateClickRequest {

    @NotNull
    private UUID shoppingItemId;

    @NotBlank
    private String provider;

    @NotBlank
    private String providerProductId;

    private UUID sessionId;

    private String sourceScreen;
}
