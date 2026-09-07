package com.homestock.modules.voice.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ParseCommandRequest {
    @NotBlank(message = "Transcript cannot be blank")
    private String transcript;
    private UUID homeId;
}
