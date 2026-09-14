package com.homestock.modules.voice.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class TextToSpeechServiceTest {

    private TextToSpeechService ttsService;

    @BeforeEach
    void setUp() {
        ttsService = new TextToSpeechService(null);
    }

    @Test
    @DisplayName("Should detect Tamil language for Tamil script characters")
    void testResolveTargetLanguageTamilScript() {
        String text = "உங்களிடம் 4 கிலோ அரிசி இருக்கு.";
        String lang = ttsService.resolveTargetLanguage(text, null);
        assertEquals("ta", lang);

        String langWithEnHint = ttsService.resolveTargetLanguage(text, "EN");
        assertEquals("ta", langWithEnHint);
    }

    @Test
    @DisplayName("Should resolve Indian English for English text")
    void testResolveTargetLanguageEnglish() {
        String text = "You have 4.2 kilograms of rice remaining.";
        String lang = ttsService.resolveTargetLanguage(text, "EN");
        assertEquals("en-IN", lang);
    }

    @Test
    @DisplayName("Should resolve Indian English for Tanglish in Latin script")
    void testResolveTargetLanguageTanglish() {
        String text = "Rice evlo irukku? Shopping list la add panniten.";
        String lang = ttsService.resolveTargetLanguage(text, "TANGLISH");
        assertEquals("en-IN", lang);

        String mixedLang = ttsService.resolveTargetLanguage(text, "MIXED");
        assertEquals("en-IN", mixedLang);
    }

    @Test
    @DisplayName("Should resolve Tamil for Tanglish containing Tamil characters")
    void testResolveTargetLanguageTanglishWithTamilScript() {
        String text = "ஆமாம், உங்கள் shopping list-ல sugar இருக்கு.";
        String lang = ttsService.resolveTargetLanguage(text, "TANGLISH");
        assertEquals("ta", lang);
    }

    @Test
    @DisplayName("Should synthesize speech and return valid MP3 bytes for Tamil and English")
    void testSynthesizeSpeechOnline() {
        // Synthesize short Tamil text
        byte[] tamilAudio = ttsService.synthesizeSpeech("அரிசி", "TA", 1.0);
        assertNotNull(tamilAudio);
        assertTrue(tamilAudio.length > 100);

        // Synthesize short English text
        byte[] englishAudio = ttsService.synthesizeSpeech("Rice added", "EN", 1.0);
        assertNotNull(englishAudio);
        assertTrue(englishAudio.length > 100);

        // Test in-memory cache hit (should return same byte array quickly)
        byte[] cachedAudio = ttsService.synthesizeSpeech("Rice added", "EN", 1.0);
        assertSame(englishAudio, cachedAudio);
    }
}
