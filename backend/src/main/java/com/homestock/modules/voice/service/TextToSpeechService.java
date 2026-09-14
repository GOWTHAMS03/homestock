package com.homestock.modules.voice.service;

import com.homestock.core.exception.BusinessRuleException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.math.BigInteger;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.WebSocket;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.TimeUnit;
import java.util.regex.Pattern;

@Slf4j
@Service
public class TextToSpeechService {

    private final StringRedisTemplate redisTemplate;
    private final HttpClient httpClient;

    // Fast in-memory cache for repeated phrases (LRU, max 500 items)
    private static final int MAX_IN_MEMORY_CACHE = 500;
    private final Map<String, byte[]> inMemoryCache = Collections.synchronizedMap(
            new LinkedHashMap<>(128, 0.75f, true) {
                @Override
                protected boolean removeEldestEntry(Map.Entry<String, byte[]> eldest) {
                    return size() > MAX_IN_MEMORY_CACHE;
                }
            }
    );

    // Microsoft Edge Neural TTS parameters
    private static final String TRUSTED_CLIENT_TOKEN = "6A5AA1D4EAFF4E9FB37E23D68491D6F4";
    private static final String SEC_MS_GEC_VERSION = "1-143.0.3650.75";
    private static final long WIN_EPOCH = 11644473600L;
    private static final String EDGE_TTS_WSS_URL = "wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1";

    // Fallback Google TTS endpoint
    private static final String GOOGLE_TTS_ENDPOINT = "https://translate.google.com/translate_tts";

    private static final Pattern TAMIL_CHAR_PATTERN = Pattern.compile("[\\u0B80-\\u0BFF]");
    private static final Duration CACHE_TTL = Duration.ofDays(7);

    @Autowired
    public TextToSpeechService(@Autowired(required = false) StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
        this.httpClient = HttpClient.newBuilder()
                .version(HttpClient.Version.HTTP_2)
                .connectTimeout(Duration.ofSeconds(10))
                .followRedirects(HttpClient.Redirect.NORMAL)
                .build();
    }

    /**
     * Synthesizes warm, friendly, cute natural female speech for the given text and language.
     *
     * @param text     The text to speak (Tamil, Indian English, Tanglish).
     * @param language Explicit language hint ("TA", "EN", "TANGLISH", "MIXED") or null.
     * @param speed    Speaking speed multiplier (0.8x - 1.2x, default 1.0).
     * @return Raw MP3 audio bytes.
     */
    public byte[] synthesizeSpeech(String text, String language, Double speed) {
        if (text == null || text.isBlank()) {
            throw new BusinessRuleException("Text cannot be empty for voice synthesis");
        }

        String cleanedText = cleanTextForSpeech(text);
        if (cleanedText.isEmpty()) {
            throw new BusinessRuleException("Text has no speakable content");
        }

        String targetLang = resolveTargetLanguage(cleanedText, language);
        double effectiveSpeed = (speed != null && speed >= 0.5 && speed <= 1.5) ? speed : 1.0;

        String cacheKey = "tts:neural_v2:" + computeHash(cleanedText + "_" + targetLang + "_" + effectiveSpeed);

        // 1. Check in-memory cache
        byte[] cachedAudio = inMemoryCache.get(cacheKey);
        if (cachedAudio != null && cachedAudio.length > 0) {
            log.debug("TTS in-memory cache hit for key: {}", cacheKey);
            return cachedAudio;
        }

        // 2. Check Redis cache if available
        if (redisTemplate != null) {
            try {
                String base64Audio = redisTemplate.opsForValue().get(cacheKey);
                if (base64Audio != null && !base64Audio.isBlank()) {
                    byte[] decoded = Base64.getDecoder().decode(base64Audio);
                    inMemoryCache.put(cacheKey, decoded);
                    log.debug("TTS Redis cache hit for key: {}", cacheKey);
                    return decoded;
                }
            } catch (Exception e) {
                log.warn("Redis read failed for TTS cache key {}: {}", cacheKey, e.getMessage());
            }
        }

        // 3. Synthesize via Microsoft Edge Neural Voice (Warm, Cute, Friendly Female)
        byte[] synthesized = null;
        try {
            synthesized = synthesizeWithEdgeNeural(cleanedText, targetLang, effectiveSpeed);
            log.info("Synthesized high-fidelity neural audio for lang={}, text length={}", targetLang, cleanedText.length());
        } catch (Exception e) {
            log.warn("Edge Neural TTS failed ({}), falling back to secondary engine...", e.getMessage());
            try {
                synthesized = fetchGoogleTtsFallback(cleanedText, targetLang, effectiveSpeed);
            } catch (Exception ex) {
                log.error("All TTS engines failed for '{}': {}", cleanedText, ex.getMessage());
                throw new BusinessRuleException("Voice synthesis failed: " + ex.getMessage());
            }
        }

        if (synthesized != null && synthesized.length > 0) {
            inMemoryCache.put(cacheKey, synthesized);
            if (redisTemplate != null) {
                try {
                    String base64 = Base64.getEncoder().encodeToString(synthesized);
                    redisTemplate.opsForValue().set(cacheKey, base64, CACHE_TTL);
                } catch (Exception e) {
                    log.warn("Redis write failed for TTS cache key {}: {}", cacheKey, e.getMessage());
                }
            }
        }

        return synthesized;
    }

    /**
     * Synthesizes audio using Microsoft Edge Neural TTS with natural female voices:
     * - en-IN-NeerjaNeural: Warm, cheerful, friendly Indian English female voice
     * - ta-IN-PallaviNeural: Clear, natural, authentic Tamil female voice
     * SSML prosody pitch is tuned (+8Hz) to sound cute and friendly rather than flat/mechanical.
     */
    private byte[] synthesizeWithEdgeNeural(String text, String targetLang, double speed) throws Exception {
        String voiceName = "ta".equalsIgnoreCase(targetLang) ? "ta-IN-PallaviNeural" : "en-IN-NeerjaNeural";
        String langCode = "ta".equalsIgnoreCase(targetLang) ? "ta-IN" : "en-IN";

        // Calculate rate percentage
        int rateDelta = (int) Math.round((speed - 1.0) * 100) + 5; // +5% baseline for lively cadence
        String rateStr = (rateDelta >= 0 ? "+" : "") + rateDelta + "%";
        // Pitch: +8Hz for a warm, cute, cheerful, friendly household assistant persona
        String pitchStr = "+8Hz";

        String escapedText = text
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&apos;");

        String ssml = String.format(
                "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='%s'>"
                        + "<voice name='%s'>"
                        + "<prosody pitch='%s' rate='%s'>%s</prosody>"
                        + "</voice></speak>",
                langCode, voiceName, pitchStr, rateStr, escapedText
        );

        String connId = UUID.randomUUID().toString().replace("-", "");
        String secMsGec = generateSecMsGec();
        String wsUrl = String.format(
                "%s?TrustedClientToken=%s&ConnectionId=%s&Sec-MS-GEC=%s&Sec-MS-GEC-Version=%s",
                EDGE_TTS_WSS_URL, TRUSTED_CLIENT_TOKEN, connId, secMsGec, SEC_MS_GEC_VERSION
        );

        CompletableFuture<byte[]> audioFuture = new CompletableFuture<>();
        List<byte[]> audioChunks = Collections.synchronizedList(new ArrayList<>());

        WebSocket ws = httpClient.newWebSocketBuilder()
                .header("Origin", "chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold")
                .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0")
                .header("Pragma", "no-cache")
                .header("Cache-Control", "no-cache")
                .buildAsync(URI.create(wsUrl), new WebSocket.Listener() {
                    @Override
                    public void onOpen(WebSocket webSocket) {
                        String configMsg = "Content-Type:application/json; charset=utf-8\r\nPath:speech.config\r\n\r\n"
                                + "{\"context\":{\"synthesis\":{\"audio\":{\"metadataoptions\":{\"sentenceBoundaryEnabled\":\"false\",\"wordBoundaryEnabled\":\"false\"},\"outputFormat\":\"audio-24khz-48kbitrate-mono-mp3\"}}}}";
                        webSocket.sendText(configMsg, true);

                        String reqId = UUID.randomUUID().toString().replace("-", "");
                        String ssmlMsg = "X-RequestId:" + reqId + "\r\nContent-Type:application/ssml+xml\r\nPath:ssml\r\n\r\n" + ssml;
                        webSocket.sendText(ssmlMsg, true);
                        WebSocket.Listener.super.onOpen(webSocket);
                    }

                    @Override
                    public CompletionStage<?> onText(WebSocket webSocket, CharSequence data, boolean last) {
                        String str = data.toString();
                        if (str.contains("Path:turn.end")) {
                            webSocket.sendClose(WebSocket.NORMAL_CLOSURE, "Done");
                            int totalLen = audioChunks.stream().mapToInt(b -> b.length).sum();
                            byte[] result = new byte[totalLen];
                            int offset = 0;
                            for (byte[] chunk : audioChunks) {
                                System.arraycopy(chunk, 0, result, offset, chunk.length);
                                offset += chunk.length;
                            }
                            audioFuture.complete(result);
                        }
                        return WebSocket.Listener.super.onText(webSocket, data, last);
                    }

                    @Override
                    public CompletionStage<?> onBinary(WebSocket webSocket, ByteBuffer data, boolean last) {
                        byte[] bytes = new byte[data.remaining()];
                        data.get(bytes);
                        // Edge TTS binary format: 2-byte header length + header + MP3 audio bytes
                        if (bytes.length > 2) {
                            int headerLen = ((bytes[0] & 0xFF) << 8) | (bytes[1] & 0xFF);
                            if (bytes.length > headerLen + 2) {
                                int audioLen = bytes.length - (headerLen + 2);
                                byte[] audio = new byte[audioLen];
                                System.arraycopy(bytes, headerLen + 2, audio, 0, audioLen);
                                audioChunks.add(audio);
                            }
                        }
                        return WebSocket.Listener.super.onBinary(webSocket, data, last);
                    }

                    @Override
                    public void onError(WebSocket webSocket, Throwable error) {
                        log.warn("Edge Neural TTS WebSocket error: {}", error.getMessage());
                        audioFuture.completeExceptionally(error);
                        WebSocket.Listener.super.onError(webSocket, error);
                    }
                }).join();

        return audioFuture.get(8, TimeUnit.SECONDS);
    }

    /**
     * Generates the Sec-MS-GEC DRM validation token required by Microsoft Edge speech synthesis.
     */
    private String generateSecMsGec() {
        try {
            long unixSec = Instant.now().getEpochSecond();
            long ticks = unixSec + WIN_EPOCH;
            ticks -= ticks % 300;
            long fileTimeTicks = ticks * 10000000L;
            String strToHash = fileTimeTicks + TRUSTED_CLIENT_TOKEN;
            MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
            byte[] hash = sha256.digest(strToHash.getBytes(StandardCharsets.US_ASCII));
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) {
                sb.append(String.format("%02X", b));
            }
            return sb.toString();
        } catch (Exception e) {
            log.warn("Failed to generate Sec-MS-GEC: {}", e.getMessage());
            return "";
        }
    }

    /**
     * Secondary fallback to Google TTS if WebSocket or Edge service is unreachable.
     */
    private byte[] fetchGoogleTtsFallback(String text, String targetLang, double speed) throws Exception {
        String encodedText = URLEncoder.encode(text, StandardCharsets.UTF_8);
        String url = String.format(
                "%s?ie=UTF-8&q=%s&tl=%s&client=tw-ob&ttsspeed=%.1f",
                GOOGLE_TTS_ENDPOINT, encodedText, targetLang, speed
        );

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36")
                .header("Accept", "audio/mpeg, audio/*; q=0.9, */*; q=0.8")
                .timeout(Duration.ofSeconds(10))
                .GET()
                .build();

        HttpResponse<byte[]> response = httpClient.send(request, HttpResponse.BodyHandlers.ofByteArray());
        if (response.statusCode() != 200) {
            throw new RuntimeException("Fallback TTS request failed with HTTP " + response.statusCode());
        }
        return response.body();
    }

    /**
     * Resolves the target language code:
     * - Tamil: "ta"
     * - Indian English / Tanglish: "en-IN"
     */
    public String resolveTargetLanguage(String text, String languageHint) {
        if (TAMIL_CHAR_PATTERN.matcher(text).find()) {
            return "ta";
        }

        if (languageHint != null && !languageHint.isBlank()) {
            String upper = languageHint.trim().toUpperCase();
            if (upper.equals("TA") || upper.contains("TAMIL")) {
                return "ta";
            }
            if (upper.equals("EN") || upper.contains("ENGLISH")) {
                return "en-IN";
            }
            if (upper.contains("TANGLISH") || upper.contains("MIXED")) {
                return "en-IN";
            }
        }

        return "en-IN";
    }

    private String cleanTextForSpeech(String text) {
        return text
                .replaceAll("[*#_`~]", "") // Remove markdown formatting
                .replaceAll("(?i)\\b(\\d+(?:\\.\\d+)?)\\s*kg\\b", "$1 kilograms")
                .replaceAll("(?i)\\b(\\d+(?:\\.\\d+)?)\\s*g\\b", "$1 grams")
                .replaceAll("(?i)\\b(\\d+(?:\\.\\d+)?)\\s*ltr?\\b", "$1 litres")
                .replaceAll("(?i)\\b(\\d+(?:\\.\\d+)?)\\s*pcs?\\b", "$1 pieces")
                .replaceAll("(?i)\\b(\\d+(?:\\.\\d+)?)\\s*pkts?\\b", "$1 packets")
                .replaceAll(":", ",") // Replace colons with commas so TTS pauses instead of pronouncing "colon"
                .replaceAll("\\s+", " ") // Normalize whitespace
                .trim();
    }

    private String computeHash(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] digest = md.digest(input.getBytes(StandardCharsets.UTF_8));
            return String.format("%032x", new BigInteger(1, digest));
        } catch (Exception e) {
            return String.valueOf(input.hashCode());
        }
    }
}
