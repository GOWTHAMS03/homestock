package com.homestock.modules.voice.dto;

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
public class ExecuteCommandRequest {
    @NotNull(message = "Home ID is required")
    private UUID homeId;

    @NotNull(message = "Command result is required")
    private VoiceCommandResult commandResult;

    private boolean confirmed;

    private String selectedOptionId;
}
