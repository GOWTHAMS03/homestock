package com.homestock.modules.notification;

import com.homestock.modules.notification.dto.DeviceTokenRequest;
import com.homestock.modules.notification.entity.DeviceToken;
import com.homestock.modules.notification.entity.PlatformType;
import com.homestock.modules.notification.repository.DeviceTokenRepository;
import com.homestock.modules.notification.service.DeviceTokenService;
import com.homestock.modules.user.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class DeviceTokenServiceTest {

    private DeviceTokenRepository tokenRepository;
    private DeviceTokenService tokenService;
    private User testUser;

    @BeforeEach
    void setUp() {
        tokenRepository = mock(DeviceTokenRepository.class);
        tokenService = new DeviceTokenService(tokenRepository);

        testUser = User.builder()
                .email("test@homestock.app")
                .fullName("Test User")
                .build();
        testUser.setId(UUID.randomUUID());
    }

    @Test
    @DisplayName("Registers new device token successfully")
    void testRegisterNewToken() {
        when(tokenRepository.findByDeviceToken(anyString())).thenReturn(Optional.empty());
        when(tokenRepository.save(any(DeviceToken.class))).thenAnswer(i -> i.getArgument(0));

        DeviceTokenRequest request = DeviceTokenRequest.builder()
                .deviceToken("fcm-test-token-12345")
                .platform(PlatformType.ANDROID)
                .deviceName("Pixel 8")
                .build();

        tokenService.registerDeviceToken(testUser, request);

        ArgumentCaptor<DeviceToken> captor = ArgumentCaptor.forClass(DeviceToken.class);
        verify(tokenRepository).save(captor.capture());

        DeviceToken saved = captor.getValue();
        assertThat(saved.getDeviceToken()).isEqualTo("fcm-test-token-12345");
        assertThat(saved.getPlatform()).isEqualTo(PlatformType.ANDROID);
        assertThat(saved.getIsActive()).isTrue();
        assertThat(saved.getUser().getId()).isEqualTo(testUser.getId());
    }

    @Test
    @DisplayName("Deactivates device token on logout")
    void testDeactivateToken() {
        tokenService.deactivateDeviceToken(testUser.getId(), "active-fcm-token");

        verify(tokenRepository).deactivateUserToken(testUser.getId(), "active-fcm-token");
    }
}

