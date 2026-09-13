package com.homestock.modules.voice.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.voice.dto.*;
import com.homestock.modules.voice.service.VoiceAuditService;
import com.homestock.modules.voice.service.VoiceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
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
    private final VoiceAuditService voiceAuditService;

    // =========================================================================
    // Legacy Endpoints (Preserved for 100% Backward Compatibility)
    // =========================================================================

    /**
     * Transcribe an audio file to text using Whisper.
     */
    @PostMapping(value = "/transcribe", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @com.homestock.core.redis.RateLimited(keyPrefix = "voice_transcribe", limit = 10, windowSeconds = 60)
    public ResponseEntity<ApiResponse<TranscriptionResult>> transcribe(
            @RequestPart("file") MultipartFile file,
            @RequestParam(value = "language", required = false) String language) {
        log.info("Received audio transcription request (filename={}, size={} bytes, lang={})",
                file.getOriginalFilename(), file.getSize(), language);
        TranscriptionResult result = voiceService.transcribe(file, language);
        return ResponseEntity.ok(ApiResponse.success("Transcription successful", result));
    }

    /**
     * Parse text transcript into an intent and extracted entities using regex/dictionary.
     */
    @PostMapping("/command")
    @com.homestock.core.redis.RateLimited(keyPrefix = "voice_command", limit = 20, windowSeconds = 60)
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
    @com.homestock.core.redis.RateLimited(keyPrefix = "voice_process_audio", limit = 10, windowSeconds = 60)
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
        VoiceIntent intent = request.getCommandResult() != null ? request.getCommandResult().getIntent() : VoiceIntent.UNKNOWN;
        log.info("Executing voice command intent {} for home {}", intent, request.getHomeId());

        if (intent == null || intent == VoiceIntent.UNKNOWN) {
            ExecuteCommandResponse failedResp = ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(VoiceIntent.UNKNOWN)
                    .message("Cannot execute unrecognized command. Please try speaking again.")
                    .executionStatus("FAILED")
                    .build();
            return ResponseEntity.ok(ApiResponse.success("Command unrecognized", failedResp));
        }

        ExecuteCommandResponse response = voiceService.execute(request);
        return ResponseEntity.ok(ApiResponse.success(response.getMessage(), response));
    }

    // =========================================================================
    // Gemini Flash-Lite Production AI Voice Endpoints
    // =========================================================================

    /**
     * End-to-end Gemini Flash-Lite audio understanding:
     * Voice Audio -> Gemini Multimodal -> Structured JSON -> Validation -> Resolution -> Candidate Ranking
     */
    @PostMapping(value = "/ai/command", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @com.homestock.core.redis.RateLimited(keyPrefix = "voice_ai_command", limit = 30, windowSeconds = 60)
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    public ResponseEntity<ApiResponse<VoiceCommandResult>> processAiVoiceCommand(
            @RequestPart("file") MultipartFile file,
            @RequestParam("homeId") UUID homeId,
            @RequestParam(value = "idempotencyKey", required = false) String idempotencyKey) {
        if (idempotencyKey != null && idempotencyKey.contains(",")) {
            idempotencyKey = idempotencyKey.split(",")[0].trim();
        }
        log.info("Processing Gemini AI voice command for home {} (size={} bytes, idemKey={})",
                homeId, file.getSize(), idempotencyKey);
        VoiceCommandResult result = voiceService.processAiAudio(file, homeId, idempotencyKey);
        return ResponseEntity.ok(ApiResponse.success("Voice command understood successfully", result));
    }

    /**
     * Parse text command using Gemini Flash-Lite for natural language & multilingual understanding.
     */
    @PostMapping("/ai/parse")
    @com.homestock.core.redis.RateLimited(keyPrefix = "voice_ai_parse", limit = 30, windowSeconds = 60)
    @PreAuthorize("@homeSecurity.isMember(#request.homeId)")
    public ResponseEntity<ApiResponse<VoiceCommandResult>> parseAiCommand(
            @Valid @RequestBody ParseCommandRequest request) {
        log.info("Parsing text command via Gemini AI: '{}' for home {}", request.getTranscript(), request.getHomeId());
        VoiceCommandResult result = voiceService.processAiText(request.getTranscript(), request.getHomeId());
        return ResponseEntity.ok(ApiResponse.success("Text command processed successfully", result));
    }

    /**
     * Handle multi-turn conversation follow-up (e.g. User said "add rice", bot asked "How much?", user says "2 kilo").
     */
    @PostMapping("/ai/follow-up")
    @com.homestock.core.redis.RateLimited(keyPrefix = "voice_ai_follow_up", limit = 30, windowSeconds = 60)
    @PreAuthorize("@homeSecurity.isMember(#request.homeId)")
    public ResponseEntity<ApiResponse<VoiceCommandResult>> followUpCommand(
            @Valid @RequestBody FollowUpRequest request) {
        log.info("Processing voice follow-up: '{}' for home {}", request.getTranscript(), request.getHomeId());
        VoiceCommandResult result = voiceService.processFollowUp(request.getHomeId(), request.getTranscript());
        return ResponseEntity.ok(ApiResponse.success("Follow-up merged successfully", result));
    }

    /**
     * Retrieve voice command audit trail for the home.
     */
    @GetMapping("/audit")
    @PreAuthorize("@homeSecurity.isMember(#homeId)")
    public ResponseEntity<ApiResponse<Page<VoiceAuditDto>>> getAuditHistory(
            @RequestParam("homeId") UUID homeId,
            @PageableDefault(size = 20) Pageable pageable) {
        Page<VoiceAuditDto> history = voiceAuditService.getAuditHistory(homeId, pageable);
        return ResponseEntity.ok(ApiResponse.success("Voice audit history retrieved", history));
    }
}
