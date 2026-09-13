package com.homestock.modules.voice.repository;

import com.homestock.modules.voice.entity.VoiceCommandAudit;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface VoiceCommandAuditRepository extends JpaRepository<VoiceCommandAudit, UUID> {

    Page<VoiceCommandAudit> findByHomeIdOrderByTimestampDesc(UUID homeId, Pageable pageable);

    Page<VoiceCommandAudit> findByUserIdOrderByTimestampDesc(UUID userId, Pageable pageable);

    Optional<VoiceCommandAudit> findByHomeIdAndIdempotencyKey(UUID homeId, String idempotencyKey);

    @Modifying
    @Query("DELETE FROM VoiceCommandAudit a WHERE a.createdAt < :cutoff")
    int deleteByCreatedAtBefore(@Param("cutoff") Instant cutoff);
}

