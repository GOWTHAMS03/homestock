package com.homestock.modules.voice.provider;

import com.homestock.modules.voice.dto.TranscriptionResult;
import org.springframework.web.multipart.MultipartFile;

public interface SpeechToTextProvider {

    String getProviderName();

    TranscriptionResult transcribe(MultipartFile audioFile, String languageHint);
}
