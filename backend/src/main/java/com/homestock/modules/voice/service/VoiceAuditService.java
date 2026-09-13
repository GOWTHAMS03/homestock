package com.homestock.modules.voice.service;

import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import com.homestock.modules.voice.config.VoiceProperties;
import com.homestock.modules.voice.dto.VoiceAuditDto;
import com.homestock.modules.voice.dto.VoiceCommandResult;
import com.homestock.modules.voice.entity.VoiceCommandAudit;
import com.homestock.modules.voice.repository.VoiceCommandAuditRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class VoiceAuditService {

    private final VoiceCommandAuditRepository auditRepository;
    private final HomeRepository homeRepository;
    private final UserRepository userRepository;
    private final VoiceProperties voiceProperties;

    @Transactional
    public VoiceCommandAudit recordCommand(UUID userId, UUID homeId, VoiceCommandResult command,
                                          String audioHash, String idempotencyKey) {
        try {
            User user = userRepository.findById(userId).orElse(null);
            Home home = homeRepository.findById(homeId).orElse(null);

            if (user == null || home == null) {
                log.warn("Cannot record voice audit: user {} or home {} not found", userId, homeId);
                return null;
            }

            var entities = command.getEntities();

            VoiceCommandAudit audit = VoiceCommandAudit.builder()
                    .user(user)
                    .home(home)
                    .timestamp(Instant.now())
                    .audioHash(audioHash)
                    .recognizedText(command.getTranscript())
                    .detectedLanguage(command.getDetectedLanguage())
                    .intent(command.getIntent() != null ? command.getIntent().name() : "UNKNOWN")
                    .productId(entities != null ? entities.getMatchedInventoryItemId() : null)
                    .productName(entities != null ? (entities.getMatchedInventoryItemName() != null
                            ? entities.getMatchedInventoryItemName() : entities.getItemName()) : null)
                    .quantity(entities != null ? entities.getQuantity() : null)
                    .unit(entities != null ? entities.getUnit() : null)
                    .target(entities != null ? entities.getTarget() : null)
                    .intentConfidence(command.getIntentConfidence())
                    .productConfidence(command.getProductMatchConfidence())
                    .executionStatus(command.getExecutionStatus() != null ? command.getExecutionStatus() : "PENDING")
                    .idempotencyKey(idempotencyKey)
                    .commandMode(command.getCommandMode() != null ? command.getCommandMode() : "COMMAND")
                    .build();

            return auditRepository.save(audit);
        } catch (Exception e) {
            log.error("Failed to record voice audit: {}", e.getMessage(), e);
            return null;
        }
    }

    @Transactional
    public void updateExecutionStatus(UUID auditId, String status, String error) {
        if (auditId == null) return;
        auditRepository.findById(auditId).ifPresent(audit -> {
            audit.setExecutionStatus(status);
            if (error != null) {
                audit.setError(error);
            }
            auditRepository.save(audit);
        });
    }

    @Transactional
    public void recordCorrection(UUID auditId, String userCorrection) {
        if (auditId == null) return;
        auditRepository.findById(auditId).ifPresent(audit -> {
            audit.setUserCorrection(userCorrection);
            auditRepository.save(audit);
        });
    }

    @Transactional(readOnly = true)
    public Page<VoiceAuditDto> getAuditHistory(UUID homeId, Pageable pageable) {
        return auditRepository.findByHomeIdOrderByTimestampDesc(homeId, pageable)
                .map(this::toDto);
    }

    @Scheduled(cron = "0 0 3 * * ?") // Daily at 3 AM
    @Transactional
    public void cleanupOldAudits() {
        int retentionDays = voiceProperties.getAudit().getRetentionDays();
        Instant cutoff = Instant.now().minus(retentionDays, ChronoUnit.DAYS);
        int deleted = auditRepository.deleteByCreatedAtBefore(cutoff);
        if (deleted > 0) {
            log.info("Cleaned up {} voice command audit logs older than {} days", deleted, retentionDays);
        }
    }

    private VoiceAuditDto toDto(VoiceCommandAudit audit) {
        return VoiceAuditDto.builder()
                .id(audit.getId())
                .timestamp(audit.getTimestamp())
                .recognizedText(audit.getRecognizedText())
                .detectedLanguage(audit.getDetectedLanguage())
                .intent(audit.getIntent())
                .productId(audit.getProductId())
                .productName(audit.getProductName())
                .quantity(audit.getQuantity())
                .unit(audit.getUnit())
                .target(audit.getTarget())
                .intentConfidence(audit.getIntentConfidence())
                .productConfidence(audit.getProductConfidence())
                .executionStatus(audit.getExecutionStatus())
                .error(audit.getError())
                .userCorrection(audit.getUserCorrection())
                .idempotencyKey(audit.getIdempotencyKey())
                .commandMode(audit.getCommandMode())
                .build();
    }
}

