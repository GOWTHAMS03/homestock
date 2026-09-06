package com.homestock.modules.user.service;

import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.core.util.SecurityUtils;
import com.homestock.modules.user.dto.DeviceTokenRequest;
import com.homestock.modules.user.dto.UpdateProfileRequest;
import com.homestock.modules.user.dto.UserDto;
import com.homestock.modules.user.entity.DeviceToken;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.DeviceTokenRepository;
import com.homestock.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final DeviceTokenRepository deviceTokenRepository;

    @Transactional(readOnly = true)
    public UserDto getCurrentUserProfile() {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        User user = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        return UserDto.fromEntity(user);
    }

    @Transactional
    public UserDto updateProfile(UpdateProfileRequest request) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        User user = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        user.setFullName(request.getFullName().trim());
        if (request.getPhoneNumber() != null) {
            user.setPhoneNumber(request.getPhoneNumber().trim());
        }
        if (request.getAvatarUrl() != null) {
            user.setAvatarUrl(request.getAvatarUrl());
        }

        User updatedUser = userRepository.save(user);
        return UserDto.fromEntity(updatedUser);
    }

    @Transactional
    public void registerDeviceToken(DeviceTokenRequest request) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        User user = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        deviceTokenRepository.findByToken(request.getToken())
                .ifPresentOrElse(
                        existing -> {
                            existing.setUser(user);
                            existing.setDeviceType(request.getDeviceType().toUpperCase());
                            existing.setLastUsedAt(Instant.now());
                            deviceTokenRepository.save(existing);
                        },
                        () -> {
                            DeviceToken token = DeviceToken.builder()
                                    .user(user)
                                    .token(request.getToken())
                                    .deviceType(request.getDeviceType().toUpperCase())
                                    .lastUsedAt(Instant.now())
                                    .build();
                            deviceTokenRepository.save(token);
                        }
                );
    }
}
