package com.homestock.modules.voice.provider;

import com.homestock.modules.voice.dto.TranscriptionResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

@Component("mockSpeechToTextProvider")
public class MockSpeechToTextProvider implements SpeechToTextProvider {

    private static final Logger log = LoggerFactory.getLogger(MockSpeechToTextProvider.class);

    @Override
    public String getProviderName() {
        return "mock";
    }

    @Override
    public TranscriptionResult transcribe(MultipartFile audioFile, String languageHint) {
        long startTime = System.currentTimeMillis();
        String originalFilename = audioFile != null ? audioFile.getOriginalFilename() : "";

        // If filename contains a test transcript (e.g. "add_rice_5kg.m4a" or encoded text)
        String transcript = "Add 2 litre cooking oil to shopping list";
        String lang = languageHint != null && !languageHint.isBlank() ? languageHint : "en";

        if (originalFilename != null) {
            String lower = originalFilename.toLowerCase();
            if (lower.contains("tamil") || lower.contains("arisi")) {
                transcript = "2 litre oil shopping list la add pannu";
                lang = "ta";
            } else if (lower.contains("milk")) {
                transcript = "Milk stock 2 packets irukku";
                lang = "ta";
            } else if (lower.contains("used")) {
                transcript = "Used 500 ml cooking oil";
                lang = "en";
            } else if (lower.contains("low")) {
                transcript = "What is running low?";
                lang = "en";
            }
        }

        long elapsed = System.currentTimeMillis() - startTime;
        log.info("MockSpeechToTextProvider transcribed audio [{}] to [{}] (lang: {}) in {}ms",
                originalFilename, transcript, lang, elapsed);

        return TranscriptionResult.builder()
                .transcript(transcript)
                .language(lang)
                .confidence(0.95)
                .processingTimeMs(Math.max(elapsed, 120))
                .build();
    }
}
