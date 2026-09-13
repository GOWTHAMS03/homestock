package com.homestock.modules.voice.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "voice_command_audit", indexes = {
        @Index(name = "idx_voice_audit_home", columnList = "home_id, timestamp"),
        @Index(name = "idx_voice_audit_user", columnList = "user_id, timestamp"),
        @Index(name = "idx_voice_audit_idem", columnList = "idempotency_key"),
        @Index(name = "idx_voice_audit_created", columnList = "created_at")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VoiceCommandAudit extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "home_id", nullable = false)
    private Home home;

    @Column(name = "timestamp", nullable = false)
    @Builder.Default
    private Instant timestamp = Instant.now();

    @Column(name = "audio_hash", length = 64)
    private String audioHash;

    @Column(name = "recognized_text", columnDefinition = "TEXT")
    private String recognizedText;

    @Column(name = "detected_language", length = 20)
    private String detectedLanguage;

    @Column(name = "intent", length = 50)
    private String intent;

    @Column(name = "product_id")
    private UUID productId;

    @Column(name = "product_name")
    private String productName;

    @Column(name = "quantity", precision = 10, scale = 3)
    private BigDecimal quantity;

    @Column(name = "unit", length = 30)
    private String unit;

    @Column(name = "target", length = 30)
    private String target;

    @Column(name = "intent_confidence")
    private Double intentConfidence;

    @Column(name = "product_confidence")
    private Double productConfidence;

    @Column(name = "execution_status", length = 30, nullable = false)
    @Builder.Default
    private String executionStatus = "PENDING";

    @Column(name = "error", columnDefinition = "TEXT")
    private String error;

    @Column(name = "user_correction", columnDefinition = "TEXT")
    private String userCorrection;

    @Column(name = "idempotency_key", length = 128)
    private String idempotencyKey;

    @Column(name = "command_mode", length = 20)
    @Builder.Default
    private String commandMode = "COMMAND";
}

