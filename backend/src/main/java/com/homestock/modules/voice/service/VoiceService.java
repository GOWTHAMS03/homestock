package com.homestock.modules.voice.service;

import com.homestock.core.exception.BusinessRuleException;
import com.homestock.modules.voice.dto.*;
import com.homestock.modules.voice.provider.SpeechToTextProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.Set;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class VoiceService {

    private final SpeechToTextProvider speechToTextProvider;
    private final VoiceCommandParser voiceCommandParser;
    private final VoiceCommandExecutor voiceCommandExecutor;

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of(
            "m4a", "mp3", "wav", "webm", "ogg", "flac", "aac", "mp4"
    );

    public TranscriptionResult transcribe(MultipartFile audioFile, String languageHint) {
        validateAudioFile(audioFile);
        return speechToTextProvider.transcribe(audioFile, languageHint);
    }

    public VoiceCommandResult parseCommand(String transcript, UUID homeId) {
        if (transcript == null || transcript.isBlank()) {
            throw new BusinessRuleException("Transcript cannot be blank");
        }
        return voiceCommandParser.parse(homeId, transcript.trim());
    }

    public VoiceCommandResult processAudio(MultipartFile audioFile, String languageHint, UUID homeId) {
        TranscriptionResult transcription = transcribe(audioFile, languageHint);
        VoiceCommandResult parsed = parseCommand(transcription.getTranscript(), homeId);
        // Ensure transcript matches exactly
        parsed.setTranscript(transcription.getTranscript());
        return parsed;
    }

    public ExecuteCommandResponse execute(ExecuteCommandRequest request) {
        return voiceCommandExecutor.execute(request);
    }

    private void validateAudioFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BusinessRuleException("Audio file is required and cannot be empty");
        }

        String originalFilename = file.getOriginalFilename();
        if (originalFilename != null && originalFilename.contains(".")) {
            String extension = originalFilename.substring(originalFilename.lastIndexOf('.') + 1).toLowerCase();
            if (!ALLOWED_EXTENSIONS.contains(extension)) {
                log.warn("Audio file extension '{}' is not in standard list, continuing if MIME type is audio", extension);
            }
        }
    }
}
