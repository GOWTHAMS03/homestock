package com.homestock.modules.voice.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "app.voice")
public class VoiceProperties {

    private String provider = "gemini";
    private Gemini gemini = new Gemini();
    private Whisper whisper = new Whisper();
    private Limits limits = new Limits();
    private Matching matching = new Matching();
    private Context context = new Context();
    private Idempotency idempotency = new Idempotency();
    private Audit audit = new Audit();
    private Confidence confidence = new Confidence();

    @Data
    public static class Gemini {
        private String apiKey = "";
        private String model = "gemini-flash-lite-latest";
        private double temperature = 0.1;
        private int maxOutputTokens = 2048;
        private int timeoutSeconds = 30;
    }

    @Data
    public static class Whisper {
        private String apiUrl = "https://api.openai.com/v1/audio/transcriptions";
        private String apiKey = "";
        private String model = "whisper-1";
        private double temperature = 0.0;
    }

    @Data
    public static class Limits {
        private int maxAudioSizeMb = 25;
        private int maxAudioDurationSeconds = 60;
    }

    @Data
    public static class Matching {
        private double confidenceThreshold = 0.80;
    }

    @Data
    public static class Context {
        private int timeoutSeconds = 120;
    }

    @Data
    public static class Idempotency {
        private int windowSeconds = 30;
    }

    @Data
    public static class Audit {
        private int retentionDays = 90;
    }

    @Data
    public static class Confidence {
        private double autoExecuteThreshold = 0.95;
        private double confirmationThreshold = 0.80;
    }
}
