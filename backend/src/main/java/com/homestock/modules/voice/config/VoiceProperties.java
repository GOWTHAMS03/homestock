package com.homestock.modules.voice.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "app.voice")
public class VoiceProperties {

    private String provider = "whisper";
    private Whisper whisper = new Whisper();
    private Limits limits = new Limits();
    private Matching matching = new Matching();

    @Data
    public static class Whisper {
        private String apiUrl = "https://api.openai.com/v1/audio/transcriptions";
        private String apiKey = "";
        private String model = "whisper-1";
        private double temperature = 0.0;
    }

    @Data
    public static class Limits {
        private int maxAudioSizeMb = 15;
        private int maxAudioDurationSeconds = 60;
    }

    @Data
    public static class Matching {
        private double confidenceThreshold = 0.80;
    }
}
