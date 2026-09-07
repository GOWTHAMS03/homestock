package com.homestock.modules.voice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExecuteCommandResponse {
    private boolean success;
    private VoiceIntent intent;
    private String message;
    private Object data;
    private Map<String, Object> navigation;
}
