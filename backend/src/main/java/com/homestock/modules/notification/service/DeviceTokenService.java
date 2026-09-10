package com.homestock.modules.notification.service;

import com.homestock.modules.notification.dto.DeviceTokenRequest;
import com.homestock.modules.notification.entity.DeviceToken;
import com.homestock.modules.notification.repository.DeviceTokenRepository;
import com.homestock.modules.user.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class DeviceTokenService {

    private final DeviceTokenRepository deviceTokenRepository;

    @Transactional
    public void registerDeviceToken(User user, DeviceTokenRequest request) {
        if (user == null || request == null || request.getDeviceToken() == null || request.getDeviceToken().isBlank()) {
            return;
        }

        String rawToken = request.getDeviceToken().trim();
        Optional<DeviceToken> existing = deviceTokenRepository.findByDeviceToken(rawToken);

        if (existing.isPresent()) {
            DeviceToken token = existing.get();
            token.setUser(user);
            token.setPlatform(request.getPlatform());
            token.setDeviceName(request.getDeviceName());
            token.setIsActive(true);
            token.setLastSeenAt(Instant.now());
            deviceTokenRepository.save(token);
            log.debug("Updated active device token for user {}", user.getId());
        } else {
            DeviceToken newToken = DeviceToken.builder()
                    .user(user)
                    .deviceToken(rawToken)
                    .platform(request.getPlatform())
                    .deviceName(request.getDeviceName())
                    .isActive(true)
                    .lastSeenAt(Instant.now())
                    .build();
            deviceTokenRepository.save(newToken);
            log.debug("Registered new device token for user {}", user.getId());
        }
    }

    @Transactional
    public void deactivateDeviceToken(UUID userId, String tokenString) {
        if (tokenString != null && !tokenString.isBlank()) {
            if (userId != null) {
                deviceTokenRepository.deactivateUserToken(userId, tokenString.trim());
            } else {
                deviceTokenRepository.deactivateToken(tokenString.trim());
            }
            log.info("Deactivated device token on logout");
        }
    }

    @Transactional(readOnly = true)
    public List<DeviceToken> getActiveTokensForUser(UUID userId) {
        return deviceTokenRepository.findAllByUserIdAndIsActiveTrue(userId);
    }

    @Transactional(readOnly = true)
    public List<DeviceToken> getActiveTokensForUsers(List<UUID> userIds) {
        if (userIds == null || userIds.isEmpty()) return List.of();
        return deviceTokenRepository.findAllByUserIdInAndIsActiveTrue(userIds);
    }
}

