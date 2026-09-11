package com.homestock.modules.notification.repository;

import com.homestock.modules.notification.entity.DeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.transaction.annotation.Transactional;

@Repository
public interface DeviceTokenRepository extends JpaRepository<DeviceToken, UUID> {
    List<DeviceToken> findAllByUserIdAndIsActiveTrue(UUID userId);

    List<DeviceToken> findAllByUserIdInAndIsActiveTrue(List<UUID> userIds);

    Optional<DeviceToken> findByDeviceToken(String deviceToken);

    @Transactional
    @Modifying
    @Query("UPDATE DeviceToken d SET d.isActive = false WHERE d.deviceToken = :token")
    void deactivateToken(@Param("token") String token);

    @Transactional
    @Modifying
    @Query("UPDATE DeviceToken d SET d.isActive = false WHERE d.user.id = :userId AND d.deviceToken = :token")
    void deactivateUserToken(@Param("userId") UUID userId, @Param("token") String token);
}

