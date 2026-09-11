package com.homestock.modules.notification.repository;

import com.homestock.modules.notification.entity.NotificationDigest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface NotificationDigestRepository extends JpaRepository<NotificationDigest, UUID> {
    List<NotificationDigest> findByHomeIdOrderByCreatedAtDesc(UUID homeId);
}
