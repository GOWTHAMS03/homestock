package com.homestock.modules.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InviteLoginRequest {

    @NotBlank(message = "Household invite code is required")
    @Size(min = 4, max = 20, message = "Invite code must be between 4 and 20 characters")
    private String inviteCode;

    @NotBlank(message = "Your full name is required")
    @Size(min = 2, max = 120, message = "Full name must be between 2 and 120 characters")
    private String fullName;

    private String email;

    private String password;
}
