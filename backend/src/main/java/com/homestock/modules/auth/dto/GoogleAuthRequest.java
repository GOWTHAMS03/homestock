package com.homestock.modules.auth.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GoogleAuthRequest {
    @NotBlank(message = "Google ID token is required")
    private String idToken;

    // Optional client-provided hints (useful for testing or fallback when token claims are decoded)
    private String email;
    private String displayName;
    private String avatarUrl;
    private String sub;
}
