package com.homestock.modules.auth;

import com.homestock.core.exception.BusinessRuleException;
import com.homestock.core.exception.UserNotFoundException;
import com.homestock.modules.auth.dto.*;
import com.homestock.modules.auth.entity.AuthIdentity;
import com.homestock.modules.auth.repository.AuthIdentityRepository;
import com.homestock.modules.auth.repository.RefreshTokenRepository;
import com.homestock.modules.auth.service.AuthService;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("local")
@Transactional
class AuthenticationServiceTest {

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AuthIdentityRepository authIdentityRepository;

    @Autowired
    private RefreshTokenRepository refreshTokenRepository;

    private RegisterRequest registerRequest;

    @BeforeEach
    void setUp() {
        registerRequest = new RegisterRequest();
        registerRequest.setEmail("alice@homestock.app");
        registerRequest.setUsername("alice01");
        registerRequest.setPassword("Password123!");
        registerRequest.setConfirmPassword("Password123!");
        registerRequest.setFullName("Alice Wonderland");
    }

    @Test
    void testRegisterWithUsernameAndLocalIdentity() {
        AuthResponse response = authService.register(registerRequest);

        assertNotNull(response);
        assertNotNull(response.getAccessToken());
        assertNotNull(response.getRefreshToken());
        assertEquals("alice01", response.getUser().getUsername());
        assertEquals("Alice Wonderland", response.getUser().getFullName());

        User savedUser = userRepository.findByEmail("alice@homestock.app").orElseThrow();
        assertEquals("alice01", savedUser.getUsername());
        assertEquals("ACTIVE", savedUser.getStatus());

        Optional<AuthIdentity> localIdentity = authIdentityRepository.findByProviderAndProviderSubject(
                "LOCAL", "alice@homestock.app");
        assertTrue(localIdentity.isPresent());
        assertEquals(savedUser.getId(), localIdentity.get().getUser().getId());
    }

    @Test
    void testRegisterMismatchedPasswordsThrowsException() {
        registerRequest.setConfirmPassword("DifferentPassword123!");
        assertThrows(BusinessRuleException.class, () -> authService.register(registerRequest));
    }

    @Test
    void testLoginWithUsernameOrEmail() {
        authService.register(registerRequest);

        // Login using email
        LoginRequest emailLogin = new LoginRequest();
        emailLogin.setEmail("alice@homestock.app");
        emailLogin.setPassword("Password123!");
        AuthResponse emailResp = authService.login(emailLogin);
        assertNotNull(emailResp.getAccessToken());

        // Login using username
        LoginRequest usernameLogin = new LoginRequest();
        usernameLogin.setEmail("alice01"); // identifier field
        usernameLogin.setPassword("Password123!");
        AuthResponse userResp = authService.login(usernameLogin);
        assertNotNull(userResp.getAccessToken());
        assertEquals("alice@homestock.app", userResp.getUser().getEmail());
    }

    @Test
    void testGoogleLoginCreatesNewUserAndIdentity() {
        GoogleAuthRequest googleReq = new GoogleAuthRequest();
        googleReq.setIdToken("mock-google-token-12345");
        googleReq.setEmail("bob.google@gmail.com");
        googleReq.setDisplayName("Bob Google");
        googleReq.setAvatarUrl("https://lh3.googleusercontent.com/a/mock");

        AuthResponse googleResp = authService.loginWithGoogle(googleReq);
        assertNotNull(googleResp);
        assertNotNull(googleResp.getAccessToken());
        assertEquals("bob.google@gmail.com", googleResp.getUser().getEmail());

        Optional<AuthIdentity> googleIdentity = authIdentityRepository.findByProviderAndProviderSubject(
                "GOOGLE", "mock-google-token-12345");
        assertTrue(googleIdentity.isPresent());
        assertEquals(googleResp.getUser().getId(), googleIdentity.get().getUser().getId());
    }

    @Test
    void testGoogleLoginLinksExistingLocalUserWithMatchingEmail() {
        // First, Alice registers locally
        authService.register(registerRequest);

        // Google sign-in with matching email "alice@homestock.app"
        GoogleAuthRequest googleReq = new GoogleAuthRequest();
        googleReq.setIdToken("google-sub-alice-999");
        googleReq.setEmail("alice@homestock.app");
        googleReq.setDisplayName("Alice From Google");

        AuthResponse linkedResp = authService.loginWithGoogle(googleReq);
        assertNotNull(linkedResp);

        User existingUser = userRepository.findByEmail("alice@homestock.app").orElseThrow();
        assertEquals(existingUser.getId(), linkedResp.getUser().getId());

        // Both identities should exist for the same user
        assertTrue(authIdentityRepository.findByProviderAndProviderSubject(
                "LOCAL", "alice@homestock.app").isPresent());
        assertTrue(authIdentityRepository.findByProviderAndProviderSubject(
                "GOOGLE", "google-sub-alice-999").isPresent());
    }

    @Test
    void testRefreshTokenRotation() {
        AuthResponse initial = authService.register(registerRequest);
        String oldRefreshToken = initial.getRefreshToken();

        RefreshTokenRequest refreshReq = new RefreshTokenRequest();
        refreshReq.setRefreshToken(oldRefreshToken);

        AuthResponse refreshed = authService.refreshToken(refreshReq);
        assertNotNull(refreshed.getAccessToken());
        assertNotNull(refreshed.getRefreshToken());
        assertNotEquals(oldRefreshToken, refreshed.getRefreshToken());

        // Old refresh token was rotated, so attempting to reuse it must fail
        assertThrows(Exception.class, () -> authService.refreshToken(refreshReq));
    }

    @Test
    void testLoginDeletedUserThrowsUserNotFoundException() {
        authService.register(registerRequest);
        User user = userRepository.findByEmail("alice@homestock.app").orElseThrow();
        user.setStatus("DELETED");
        user.setDeletedAt(Instant.now());
        userRepository.save(user);

        LoginRequest login = new LoginRequest();
        login.setEmail("alice@homestock.app");
        login.setPassword("Password123!");

        assertThrows(UserNotFoundException.class, () -> authService.login(login));
    }
}
