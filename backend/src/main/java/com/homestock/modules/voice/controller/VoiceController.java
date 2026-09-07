package com.homestock.modules.voice.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.voice.dto.*;
import com.homestock.modules.voice.service.VoiceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/v1/voice")
@RequiredArgsConstructor
public class VoiceController {

    private final VoiceService voiceService;

    /**
     * Transcribe an audio file to text using Whisper.
     */
    @PostMapping(value = "/transcribe", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<TranscriptionResult>> transcribe(
            @RequestPart("file") MultipartFile file,
            @RequestParam(value = "language", required = false) String language) {
        log.info("Received audio transcription request (filename={}, size={} bytes, lang={})",
                file.getOriginalFilename(), file.getSize(), language);
        TranscriptionResult result = voiceService.transcribe(file, language);
        return ResponseEntity.ok(ApiResponse.success("Transcription successful", result));
    }

    /**
     * Parse text transcript into an intent and extracted entities.
     */
    @PostMapping("/command")
    @PreAuthorize("#request.homeId == null or @homeSecurity.isMember(#request.homeId)")
    public ResponseEntity<ApiResponse<VoiceCommandResult>> parseCommand(
            @Valid @RequestBody ParseCommandRequest request) {
        log.info("Parsing voice command: '{}' for home {}", request.getTranscript(), request.getHomeId());
        VoiceCommandResult result = voiceService.parseCommand(request.getTranscript(), request.getHomeId());
        return ResponseEntity.ok(ApiResponse.success("Command parsed successfully", result));
    }

    /**
     * End-to-end audio processing: transcribes audio and parses it for a home in one request.
     */
    @PostMapping(value = "/process-audio", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    public ResponseEntity<ApiResponse<VoiceCommandResult>> processAudio(
            @RequestPart("file") MultipartFile file,
            @RequestParam("homeId") UUID homeId,
            @RequestParam(value = "language", required = false) String language) {
        log.info("Processing voice audio for home {} (size={} bytes)", homeId, file.getSize());
        VoiceCommandResult result = voiceService.processAudio(file, language, homeId);
        return ResponseEntity.ok(ApiResponse.success("Voice command processed successfully", result));
    }

    /**
     * Execute a validated or confirmed voice command against HomeStock domain services.
     */
    @PostMapping("/execute")
    @PreAuthorize("@homeSecurity.isMember(#request.homeId)")
    public ResponseEntity<ApiResponse<ExecuteCommandResponse>> executeCommand(
            @Valid @RequestBody ExecuteCommandRequest request) {
        log.info("Executing voice command intent {} for home {}",
                request.getCommandResult() != null ? request.getCommandResult().getIntent() : "UNKNOWN",
                request.getHomeId());
        ExecuteCommandResponse response = voiceService.execute(request);
        return ResponseEntity.ok(ApiResponse.success(response.getMessage(), response));
    }
}
