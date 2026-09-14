package com.homestock.modules.voice.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TtsRequestDto {

    @NotBlank(message = "Text cannot be blank")
    private String text;

    private String language; // "TA", "EN", "TANGLISH", "MIXED", or null

    @Builder.Default
    private Double speed = 1.0; // 0.8 to 1.2
}
