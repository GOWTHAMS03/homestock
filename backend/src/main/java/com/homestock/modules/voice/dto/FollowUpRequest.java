package com.homestock.modules.voice.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FollowUpRequest {
    @NotNull(message = "Home ID is required")
    private UUID homeId;

    @NotBlank(message = "Transcript is required")
    private String transcript;

    private String commandMode;
}

