package com.homestock.modules.home.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class JoinHomeRequest {
    @NotBlank(message = "Invite code is required")
    private String inviteCode;
}
