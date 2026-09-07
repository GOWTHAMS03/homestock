package com.homestock.modules.voice.service;

import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class NumberNormalizationService {

    private static final Map<String, BigDecimal> NUMBER_WORDS = new HashMap<>();

    static {
        // English words
        put("zero", 0);
        put("one", 1);
        put("two", 2);
        put("three", 3);
        put("four", 4);
        put("five", 5);
        put("six", 6);
        put("seven", 7);
        put("eight", 8);
        put("nine", 9);
        put("ten", 10);
        put("eleven", 11);
        put("twelve", 12);
        put("thirteen", 13);
        put("fourteen", 14);
        put("fifteen", 15);
        put("twenty", 20);
        put("twenty five", 25);
        put("fifty", 50);
        put("hundred", 100);
        put("half", 0.5);
        put("quarter", 0.25);
        put("a", 1);
        put("an", 1);

        // Tamil Script Numerals & Fractions
        put("பூஜ்ஜியம்", 0);
        put("ஒன்று", 1);
        put("ஒரு", 1);
        put("இரண்டு", 2);
        put("மூன்று", 3);
        put("நான்கு", 4);
        put("ஐந்து", 5);
        put("ஆறு", 6);
        put("ஏழு", 7);
        put("எட்டு", 8);
        put("ஒன்பது", 9);
        put("பத்து", 10);
        put("இருபது", 20);
        put("ஐம்பது", 50);
        put("நூறு", 100);

        put("அரை", 0.5);
        put("கால்", 0.25);
        put("முக்கால்", 0.75);
        put("ஒன்றரை", 1.5);
        put("இரண்டரை", 2.5);
        put("மூன்றரை", 3.5);

        // Tanglish Numerals & Fractions
        put("onnu", 1);
        put("oru", 1);
        put("rendu", 2);
        put("irandu", 2);
        put("moonu", 3);
        put("naalu", 4);
        put("naangu", 4);
        put("anju", 5);
        put("aindhu", 5);
        put("aaru", 6);
        put("ezhu", 7);
        put("yelu", 7);
        put("ettu", 8);
        put("ombadhu", 9);
        put("ombathu", 9);
        put("pathu", 10);
        put("iruvadhu", 20);
        put("irubadhu", 20);

        put("arai", 0.5);
        put("kaal", 0.25);
        put("mukkaal", 0.75);
        put("muthukaal", 0.75);
        put("onnara", 1.5);
        put("ondrai", 1.5);
        put("rendara", 2.5);
        put("moonara", 3.5);
    }

    private static void put(String word, double value) {
        NUMBER_WORDS.put(word.toLowerCase(), BigDecimal.valueOf(value));
    }

    private static void put(String word, int value) {
        NUMBER_WORDS.put(word.toLowerCase(), BigDecimal.valueOf(value));
    }

    /**
     * Parses a string token into a BigDecimal if it represents a recognized digit or number word.
     */
    public BigDecimal parseToken(String token) {
        if (token == null || token.isBlank()) return null;
        String clean = token.trim().toLowerCase().replaceAll("[;:!?,]", "").replaceAll("\\.+$", "").replaceAll("^\\.+", "");

        // 1. Direct number matching (e.g. "2", "2.5", "500")
        try {
            return new BigDecimal(clean);
        } catch (NumberFormatException ignored) {}

        // 2. Word dictionary match
        return NUMBER_WORDS.get(clean);
    }

    /**
     * Finds the first explicit quantity number in a sentence (either digits or word).
     */
    public BigDecimal extractFirstNumber(String sentence) {
        if (sentence == null || sentence.isBlank()) return null;

        // Try numeric regex first (e.g. 5, 2.5, 500)
        Pattern numPattern = Pattern.compile("\\b(\\d+(\\.\\d+)?)\\b");
        Matcher matcher = numPattern.matcher(sentence);
        if (matcher.find()) {
            try {
                return new BigDecimal(matcher.group(1));
            } catch (NumberFormatException ignored) {}
        }

        // Try word tokens
        String[] tokens = sentence.split("\\s+");
        for (String token : tokens) {
            BigDecimal val = parseToken(token);
            if (val != null && val.compareTo(BigDecimal.ZERO) > 0) {
                return val;
            }
        }

        return null;
    }
}
