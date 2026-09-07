package com.homestock.modules.voice.provider;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.homestock.core.exception.BusinessRuleException;
import com.homestock.modules.voice.config.VoiceProperties;
import com.homestock.modules.voice.dto.TranscriptionResult;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Primary;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@Component("whisperSpeechToTextProvider")
@Primary
@RequiredArgsConstructor
public class WhisperSpeechToTextProvider implements SpeechToTextProvider {

    private static final Logger log = LoggerFactory.getLogger(WhisperSpeechToTextProvider.class);

    private final VoiceProperties voiceProperties;
    private final MockSpeechToTextProvider mockProvider;
    private final ObjectMapper objectMapper;

    @Override
    public String getProviderName() {
        return "whisper";
    }

    @Override
    public TranscriptionResult transcribe(MultipartFile audioFile, String languageHint) {
        if (audioFile == null || audioFile.isEmpty()) {
            throw new BusinessRuleException("Audio file cannot be empty");
        }

        // Validate file size limit
        long maxBytes = (long) voiceProperties.getLimits().getMaxAudioSizeMb() * 1024 * 1024;
        if (audioFile.getSize() > maxBytes) {
            throw new BusinessRuleException("Audio file exceeds maximum size of " +
                    voiceProperties.getLimits().getMaxAudioSizeMb() + "MB");
        }

        String apiKey = voiceProperties.getWhisper().getApiKey();
        if (apiKey == null || apiKey.isBlank()) {
            log.warn("OpenAI API key not configured for Whisper; falling back to MockSpeechToTextProvider");
            return mockProvider.transcribe(audioFile, languageHint);
        }

        long startTime = System.currentTimeMillis();
        try {
            byte[] fileBytes = audioFile.getBytes();
            String filename = audioFile.getOriginalFilename() != null && !audioFile.getOriginalFilename().isBlank()
                    ? audioFile.getOriginalFilename()
                    : "audio.m4a";

            ByteArrayResource resource = new ByteArrayResource(fileBytes) {
                @Override
                public String getFilename() {
                    return filename;
                }
            };

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("file", resource);
            body.add("model", voiceProperties.getWhisper().getModel());
            body.add("temperature", voiceProperties.getWhisper().getTemperature());
            if (languageHint != null && !languageHint.isBlank()) {
                body.add("language", languageHint.trim().toLowerCase());
            }

            SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
            requestFactory.setConnectTimeout(10000);
            requestFactory.setReadTimeout(30000);

            RestClient restClient = RestClient.builder()
                    .requestFactory(requestFactory)
                    .baseUrl(voiceProperties.getWhisper().getApiUrl())
                    .defaultHeader(HttpHeaders.AUTHORIZATION, "Bearer " + apiKey)
                    .build();

            String responseBody = restClient.post()
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(body)
                    .retrieve()
                    .body(String.class);

            long elapsed = System.currentTimeMillis() - startTime;
            JsonNode jsonNode = objectMapper.readTree(responseBody);
            String transcript = jsonNode.path("text").asText("").trim();
            String detectedLang = jsonNode.has("language") ? jsonNode.path("language").asText() : (languageHint != null ? languageHint : "auto");

            log.info("Whisper successfully transcribed audio ({} bytes) in {}ms: [{}]",
                    fileBytes.length, elapsed, transcript);

            return TranscriptionResult.builder()
                    .transcript(transcript)
                    .language(detectedLang)
                    .confidence(0.95)
                    .processingTimeMs(elapsed)
                    .build();

        } catch (IOException e) {
            log.error("Failed to read audio file bytes for Whisper transcription", e);
            throw new BusinessRuleException("Failed to read audio file: " + e.getMessage());
        } catch (Exception e) {
            log.error("Error communicating with Whisper API, falling back to mock provider: {}", e.getMessage());
            return mockProvider.transcribe(audioFile, languageHint);
        }
    }
}
