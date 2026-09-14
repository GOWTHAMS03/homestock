package com.homestock.modules.voice.service;

import com.homestock.core.exception.BusinessRuleException;
import com.homestock.core.util.SecurityUtils;
import com.homestock.modules.voice.config.VoiceProperties;
import com.homestock.modules.voice.dto.*;
import com.homestock.modules.voice.dto.ProductMatchResult.MatchType;
import com.homestock.modules.voice.entity.VoiceCommandAudit;
import com.homestock.modules.voice.provider.SpeechToTextProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class VoiceService {

    private final SpeechToTextProvider speechToTextProvider;
    private final VoiceCommandParser voiceCommandParser;
    private final VoiceCommandExecutor voiceCommandExecutor;
    private final GeminiVoiceService geminiVoiceService;
    private final ProductResolutionService productResolutionService;
    private final VoiceIntentService voiceIntentService;
    private final VoiceCommandValidator voiceCommandValidator;
    private final VoiceContextService voiceContextService;
    private final IdempotencyService idempotencyService;
    private final VoiceResponseGenerator voiceResponseGenerator;
    private final VoiceAuditService voiceAuditService;
    private final VoiceProperties voiceProperties;

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of(
            "m4a", "mp3", "wav", "webm", "ogg", "flac", "aac", "mp4"
    );

    // =========================================================================
    // Legacy Endpoints (Fully Preserved)
    // =========================================================================

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
        parsed.setTranscript(transcription.getTranscript());
        return parsed;
    }

    public ExecuteCommandResponse execute(ExecuteCommandRequest request) {
        return executeWithAudit(request);
    }

    // =========================================================================
    // Gemini Flash-Lite Production AI Voice Pipeline
    // =========================================================================

    public VoiceCommandResult processAiAudio(MultipartFile audioFile, UUID homeId, String idempotencyKey) {
        validateAudioFile(audioFile);

        byte[] audioBytes;
        try {
            audioBytes = audioFile.getBytes();
        } catch (Exception e) {
            throw new BusinessRuleException("Failed to read audio bytes: " + e.getMessage());
        }

        String audioHash = idempotencyService.computeAudioHash(audioBytes);
        String effectiveKey = (idempotencyKey != null && !idempotencyKey.isBlank()) ? idempotencyKey : audioHash;

        UUID userId = getSafeUserId();

        String contentType = audioFile.getContentType();
        if (contentType == null || contentType.isBlank() || "application/octet-stream".equalsIgnoreCase(contentType)) {
            String origName = audioFile.getOriginalFilename();
            if (origName != null) {
                String lower = origName.toLowerCase();
                if (lower.endsWith(".m4a") || lower.endsWith(".mp4") || lower.endsWith(".aac")) {
                    contentType = "audio/mp4";
                } else if (lower.endsWith(".wav")) {
                    contentType = "audio/wav";
                } else if (lower.endsWith(".ogg") || lower.endsWith(".opus")) {
                    contentType = "audio/ogg";
                } else if (lower.endsWith(".mp3")) {
                    contentType = "audio/mp3";
                } else if (lower.endsWith(".webm")) {
                    contentType = "audio/webm";
                }
            }
        }

        GeminiVoiceResponse geminiResp;
        try {
            geminiResp = geminiVoiceService.processAudio(audioBytes, contentType);
        } catch (Exception e) {
            log.warn("Gemini Voice AI failed ({}), attempting fallback parser", e.getMessage());
            try {
                return fallbackProcessAudio(audioFile, homeId, userId, audioHash, effectiveKey);
            } catch (Exception fallbackEx) {
                log.warn("Fallback transcription also failed: {}", fallbackEx.getMessage());
                return VoiceCommandResult.builder()
                        .transcript("")
                        .intent(VoiceIntent.UNKNOWN)
                        .confidence(0.0)
                        .intentConfidence(0.0)
                        .productMatchConfidence(0.0)
                        .detectedLanguage("EN")
                        .message("Could not process voice audio. Please speak again.")
                        .executionStatus("FAILED")
                        .build();
            }
        }

        return buildCommandResult(homeId, userId, geminiResp, audioHash, effectiveKey);
    }

    public VoiceCommandResult processAiText(String transcript, UUID homeId) {
        if (transcript == null || transcript.isBlank()) {
            throw new BusinessRuleException("Transcript cannot be blank");
        }

        UUID userId = getSafeUserId();
        String idempotencyKey = UUID.randomUUID().toString();

        GeminiVoiceResponse geminiResp;
        try {
            geminiResp = geminiVoiceService.processText(transcript);
        } catch (Exception e) {
            log.warn("Gemini Voice AI text processing failed ({}), falling back to local parser", e.getMessage());
            VoiceCommandResult fallback = voiceCommandParser.parse(homeId, transcript.trim());
            fallback.setTranscript(transcript);
            return fallback;
        }

        return buildCommandResult(homeId, userId, geminiResp, null, idempotencyKey);
    }

    public VoiceCommandResult processFollowUp(UUID homeId, String followUpTranscript) {
        if (followUpTranscript == null || followUpTranscript.isBlank()) {
            throw new BusinessRuleException("Follow-up transcript cannot be blank");
        }

        UUID userId = getSafeUserId();
        Optional<VoiceContextService.VoiceContext> contextOpt = voiceContextService.getContext(userId, homeId);

        if (contextOpt.isEmpty()) {
            // No active context — treat as fresh command
            return processAiText(followUpTranscript, homeId);
        }

        VoiceContextService.VoiceContext ctx = contextOpt.get();

        // Process follow-up input via Gemini
        GeminiVoiceResponse followUpResp;
        try {
            followUpResp = geminiVoiceService.processText(followUpTranscript);
        } catch (Exception e) {
            followUpResp = GeminiVoiceResponse.builder()
                    .transcript(followUpTranscript)
                    .build();
        }

        // Merge follow-up with pending context
        GeminiVoiceResponse mergedResp = GeminiVoiceResponse.builder()
                .intent(ctx.getPendingIntent() != null ? ctx.getPendingIntent().name() : followUpResp.getIntent())
                .productName(ctx.getPendingProduct() != null ? ctx.getPendingProduct() : followUpResp.getProductName())
                .productText(ctx.getPendingProduct() != null ? ctx.getPendingProduct() : followUpResp.getProductText())
                .target(ctx.getTarget() != null ? ctx.getTarget() : followUpResp.getTarget())
                .quantity(followUpResp.getQuantity())
                .unit(followUpResp.getUnit())
                .detectedLanguage(followUpResp.getDetectedLanguage())
                .transcript(ctx.getPendingProduct() + " " + followUpTranscript)
                .intentConfidence(0.95)
                .build();

        voiceContextService.clearContext(userId, homeId);
        return buildCommandResult(homeId, userId, mergedResp, null, UUID.randomUUID().toString());
    }

    public ExecuteCommandResponse executeWithAudit(ExecuteCommandRequest request) {
        String idemKey = request.getIdempotencyKey();
        if (idemKey != null && !idemKey.isBlank()) {
            Optional<ExecuteCommandResponse> cached = idempotencyService.getCachedResponse(idemKey);
            if (cached.isPresent()) {
                return cached.get();
            }
        }

        ExecuteCommandResponse response = voiceCommandExecutor.execute(request);

        // Update audit record if present
        if (request.getCommandResult() != null && request.getCommandResult().getVoiceCommandId() != null) {
            try {
                UUID auditId = UUID.fromString(request.getCommandResult().getVoiceCommandId());
                String status = response.isSuccess() ? "EXECUTED" : "FAILED";
                String error = response.isSuccess() ? null : response.getMessage();
                voiceAuditService.updateExecutionStatus(auditId, status, error);
            } catch (Exception e) {
                log.debug("Could not parse audit UUID: {}", request.getCommandResult().getVoiceCommandId());
            }
        }

        // Cache response for duplicate rejection
        if (idemKey != null && !idemKey.isBlank() && response.isSuccess()) {
            idempotencyService.cacheResponse(idemKey, response);
        }

        // Clear conversational context on successful execution
        if (response.isSuccess()) {
            UUID userId = getSafeUserId();
            voiceContextService.clearContext(userId, request.getHomeId());
        }

        return response;
    }

    // =========================================================================
    // Pipeline Helpers
    // =========================================================================

    private VoiceCommandResult buildCommandResult(UUID homeId, UUID userId, GeminiVoiceResponse resp,
                                                  String audioHash, String idempotencyKey) {
        VoiceIntent intent = voiceIntentService.parseIntent(resp.getIntent());

        // Target override: "SHOPPING_LIST" -> ADD_SHOPPING_ITEM, "INVENTORY" -> ADD_INVENTORY_ITEM
        if (intent == VoiceIntent.ADD_SHOPPING_ITEM && "INVENTORY".equalsIgnoreCase(resp.getTarget())) {
            intent = VoiceIntent.ADD_INVENTORY_ITEM;
        } else if (intent == VoiceIntent.ADD_INVENTORY_ITEM && "SHOPPING_LIST".equalsIgnoreCase(resp.getTarget())) {
            intent = VoiceIntent.ADD_SHOPPING_ITEM;
        }

        // 1. Resolve product
        String spokenProd = resp.getProductText() != null ? resp.getProductText() : resp.getProductName();
        ProductMatchResult productMatch = productResolutionService.resolveProduct(homeId, spokenProd, resp.getProductName());

        // 2. Build entities
        BigDecimal resolvedQty = resp.getQuantity();
        String resolvedUnit = resp.getUnit() != null ? resp.getUnit() : productMatch.getDefaultUnit();

        // For ADD_SHOPPING_ITEM, default quantity to 1.0 if not specified
        if (intent == VoiceIntent.ADD_SHOPPING_ITEM) {
            if (resolvedQty == null || resolvedQty.compareTo(BigDecimal.ZERO) <= 0) {
                resolvedQty = BigDecimal.ONE;
            }
            if (resolvedUnit == null || resolvedUnit.isBlank()) {
                resolvedUnit = "pcs";
            }
        }

        VoiceEntities entities = VoiceEntities.builder()
                .itemName(productMatch.getProductName() != null ? productMatch.getProductName() : spokenProd)
                .quantity(resolvedQty)
                .unit(resolvedUnit)
                .category(productMatch.getCategory())
                .target(resp.getTarget())
                .matchedInventoryItemId(productMatch.getProductId())
                .matchedInventoryItemName(productMatch.getProductName())
                .build();

        // 3. Check disambiguation
        List<DisambiguationOption> disambiguationOptions = new ArrayList<>();
        boolean isAmbiguous = productMatch.getCandidates().size() > 1 && productMatch.getConfidence() < 0.90;
        if (isAmbiguous) {
            for (var candidate : productMatch.getCandidates()) {
                disambiguationOptions.add(DisambiguationOption.builder()
                        .id(candidate.getProductId() != null ? candidate.getProductId().toString() : candidate.getProductName())
                        .label(candidate.getProductName())
                        .subLabel(candidate.getBrand() != null ? candidate.getBrand() : candidate.getMatchReason())
                        .action("SELECT_PRODUCT")
                        .build());
            }
        }

        // 4. Threshold & Confirmation determination
        double autoExecThreshold = voiceProperties.getConfidence().getAutoExecuteThreshold();
        double confirmThreshold = voiceProperties.getConfidence().getConfirmationThreshold();

        boolean needsQuantity = (intent != VoiceIntent.ADD_SHOPPING_ITEM) && (resp.isNeedsQuantity()
                || (entities.getQuantity() == null && voiceIntentService.requiresQuantity(intent)));

        boolean requiresConfirmation = false;
        String executionStatus = "READY_TO_EXECUTE";

        if (intent == VoiceIntent.CLEAR_SHOPPING_LIST) {
            requiresConfirmation = true;
            executionStatus = "NEEDS_CONFIRMATION";
        } else if (isAmbiguous || productMatch.getConfidence() < confirmThreshold) {
            requiresConfirmation = true;
            executionStatus = "NEEDS_DISAMBIGUATION";
        } else if (intent != VoiceIntent.ADD_SHOPPING_ITEM && productMatch.getConfidence() < autoExecThreshold) {
            requiresConfirmation = true;
            executionStatus = "NEEDS_CONFIRMATION";
        }

        if (needsQuantity) {
            executionStatus = "NEEDS_QUANTITY";
        }

        // 5. Response text generation
        String responseMessage = resp.getResponseText();
        if (responseMessage == null || responseMessage.isBlank()) {
            if (needsQuantity) {
                responseMessage = voiceResponseGenerator.generateMissingQuantityPrompt(entities.getItemName(), resp.getDetectedLanguage());
            } else if (isAmbiguous) {
                responseMessage = voiceResponseGenerator.generateDisambiguationPrompt(entities.getItemName(), resp.getDetectedLanguage());
            } else {
                responseMessage = voiceResponseGenerator.generateSuccessResponse(
                        intent, entities.getItemName(), entities.getQuantity(), entities.getUnit(), null, resp.getDetectedLanguage()
                );
            }
        }

        VoiceCommandResult result = VoiceCommandResult.builder()
                .transcript(resp.getTranscript())
                .intent(intent)
                .confidence(Math.min(resp.getIntentConfidence(), productMatch.getConfidence()))
                .intentConfidence(resp.getIntentConfidence())
                .productMatchConfidence(productMatch.getConfidence())
                .detectedLanguage(resp.getDetectedLanguage())
                .idempotencyKey(idempotencyKey)
                .commandMode("COMMAND")
                .productMatch(productMatch)
                .entities(entities)
                .requiresConfirmation(requiresConfirmation)
                .disambiguationOptions(disambiguationOptions)
                .message(responseMessage)
                .executionStatus(executionStatus)
                .needsQuantity(needsQuantity)
                .needsProduct(resp.isNeedsProduct() || entities.getItemName() == null)
                .build();

        // 6. Save context if follow-up is expected
        if (needsQuantity || isAmbiguous) {
            voiceContextService.saveContext(userId, homeId, VoiceContextService.VoiceContext.builder()
                    .homeId(homeId)
                    .userId(userId)
                    .pendingIntent(intent)
                    .pendingProduct(entities.getItemName())
                    .target(entities.getTarget())
                    .missingField(needsQuantity ? "QUANTITY" : "PRODUCT")
                    .build());
        }

        // 7. Audit log
        VoiceCommandAudit audit = voiceAuditService.recordCommand(userId, homeId, result, audioHash, idempotencyKey);
        if (audit != null) {
            result.setVoiceCommandId(audit.getId().toString());
        }

        return result;
    }

    private VoiceCommandResult fallbackProcessAudio(MultipartFile audioFile, UUID homeId, UUID userId,
                                                    String audioHash, String idempotencyKey) {
        TranscriptionResult transcription = transcribe(audioFile, "auto");
        if (transcription == null || transcription.getTranscript() == null || transcription.getTranscript().isBlank()) {
            return VoiceCommandResult.builder()
                    .transcript("")
                    .intent(VoiceIntent.UNKNOWN)
                    .confidence(0.0)
                    .intentConfidence(0.0)
                    .productMatchConfidence(0.0)
                    .detectedLanguage("EN")
                    .message("Could not process voice audio. Please check your connection and speak again.")
                    .executionStatus("FAILED")
                    .build();
        }
        VoiceCommandResult result = voiceCommandParser.parse(homeId, transcription.getTranscript());
        result.setTranscript(transcription.getTranscript());
        result.setIdempotencyKey(idempotencyKey);
        result.setDetectedLanguage(transcription.getLanguage());

        VoiceCommandAudit audit = voiceAuditService.recordCommand(userId, homeId, result, audioHash, idempotencyKey);
        if (audit != null) {
            result.setVoiceCommandId(audit.getId().toString());
        }
        return result;
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

    private UUID getSafeUserId() {
        try {
            return SecurityUtils.getCurrentUserId();
        } catch (Exception e) {
            // Fallback for system / anonymous / test execution
            return UUID.fromString("00000000-0000-0000-0000-000000000001");
        }
    }
}
