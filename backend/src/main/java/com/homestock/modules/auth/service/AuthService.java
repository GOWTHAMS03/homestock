package com.homestock.modules.auth.service;

import com.homestock.core.exception.BusinessRuleException;
import com.homestock.core.exception.UnauthorizedException;
import com.homestock.core.security.JwtTokenProvider;
import com.homestock.core.security.UserPrincipal;
import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.auth.dto.AuthResponse;
import com.homestock.modules.auth.dto.InviteLoginRequest;
import com.homestock.modules.auth.dto.LoginRequest;
import com.homestock.modules.auth.dto.RefreshTokenRequest;
import com.homestock.modules.auth.dto.RegisterRequest;
import com.homestock.modules.auth.entity.RefreshToken;
import com.homestock.modules.auth.repository.RefreshTokenRepository;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.entity.HomeMember;
import com.homestock.modules.home.entity.HomeRole;
import com.homestock.modules.home.repository.HomeMemberRepository;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.user.dto.UserDto;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final HomeRepository homeRepository;
    private final HomeMemberRepository homeMemberRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

    @Value("${app.jwt.access-token-expiration-ms:86400000}")
    private long accessTokenExpirationMs;

    @Value("${app.jwt.refresh-token-expiration-ms:2592000000}")
    private long refreshTokenExpirationMs;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail().toLowerCase().trim())) {
            throw new BusinessRuleException("EMAIL_ALREADY_EXISTS", "A user with this email address already exists.");
        }

        User user = User.builder()
                .email(request.getEmail().toLowerCase().trim())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .fullName(request.getFullName().trim())
                .phoneNumber(request.getPhoneNumber())
                .isActive(true)
                .build();

        User savedUser = userRepository.save(user);
        return generateAuthResponse(savedUser);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail().toLowerCase().trim())
                .orElseThrow(() -> new org.springframework.security.authentication.BadCredentialsException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new org.springframework.security.authentication.BadCredentialsException("Invalid email or password");
        }

        if (!Boolean.TRUE.equals(user.getIsActive())) {
            throw new UnauthorizedException("User account is deactivated");
        }

        return generateAuthResponse(user);
    }

    @Transactional
    public AuthResponse loginWithInviteCode(InviteLoginRequest request) {
        String cleanCode = request.getInviteCode().trim().toUpperCase();
        Home home = homeRepository.findByInviteCode(cleanCode)
                .orElseThrow(() -> new ResourceNotFoundException("Invalid household invite code: " + cleanCode));

        String fullName = request.getFullName().trim();
        String candidateEmail = request.getEmail() != null && !request.getEmail().trim().isEmpty()
                ? request.getEmail().trim().toLowerCase()
                : null;

        User user;
        if (candidateEmail != null) {
            user = userRepository.findByEmail(candidateEmail)
                    .orElseGet(() -> {
                        String rawPassword = request.getPassword() != null && !request.getPassword().trim().isEmpty()
                                ? request.getPassword()
                                : UUID.randomUUID().toString();
                        return userRepository.save(User.builder()
                                .email(candidateEmail)
                                .passwordHash(passwordEncoder.encode(rawPassword))
                                .fullName(fullName)
                                .isActive(true)
                                .build());
                    });
        } else {
            String sanitizedName = fullName.toLowerCase().replaceAll("[^a-z0-9]", "");
            if (sanitizedName.isEmpty()) sanitizedName = "member";
            String uniqueEmail = sanitizedName + "." + cleanCode.toLowerCase() + "@homestock.local";

            user = userRepository.findByEmail(uniqueEmail)
                    .orElseGet(() -> {
                        String rawPassword = UUID.randomUUID().toString();
                        return userRepository.save(User.builder()
                                .email(uniqueEmail)
                                .passwordHash(passwordEncoder.encode(rawPassword))
                                .fullName(fullName)
                                .isActive(true)
                                .build());
                    });
        }

        if (!Boolean.TRUE.equals(user.getIsActive())) {
            throw new UnauthorizedException("User account is deactivated");
        }

        // Add user as HomeMember if not already in this household
        if (!homeMemberRepository.existsByHomeIdAndUserId(home.getId(), user.getId())) {
            HomeMember newMember = HomeMember.builder()
                    .home(home)
                    .user(user)
                    .role(HomeRole.MEMBER)
                    .build();
            homeMemberRepository.save(newMember);
        }

        return generateAuthResponse(user);
    }

    @Transactional
    public AuthResponse refreshToken(RefreshTokenRequest request) {
        RefreshToken refreshToken = refreshTokenRepository.findByTokenHash(request.getRefreshToken())
                .orElseThrow(() -> new UnauthorizedException("Invalid refresh token"));

        if (refreshToken.getRevoked() || refreshToken.isExpired()) {
            refreshTokenRepository.delete(refreshToken);
            throw new UnauthorizedException("Refresh token is expired or revoked");
        }

        User user = refreshToken.getUser();
        UserPrincipal principal = UserPrincipal.create(user);
        String newAccessToken = jwtTokenProvider.generateAccessToken(principal);

        // Sliding expiration window: extend refresh token expiration on each refresh so session stays alive
        refreshToken.setExpiresAt(Instant.now().plusMillis(refreshTokenExpirationMs));
        refreshTokenRepository.save(refreshToken);

        return AuthResponse.builder()
                .accessToken(newAccessToken)
                .refreshToken(refreshToken.getTokenHash())
                .tokenType("Bearer")
                .expiresIn(accessTokenExpirationMs / 1000)
                .user(UserDto.fromEntity(user))
                .build();
    }

    @Transactional
    public void logout(String refreshToken) {
        if (refreshToken != null) {
            refreshTokenRepository.findByTokenHash(refreshToken).ifPresent(token -> {
                token.setRevoked(true);
                refreshTokenRepository.save(token);
            });
        }
    }

    private AuthResponse generateAuthResponse(User user) {
        UserPrincipal principal = UserPrincipal.create(user);
        String accessToken = jwtTokenProvider.generateAccessToken(principal);

        // Generate and persist refresh token
        RefreshToken refreshToken = RefreshToken.builder()
                .user(user)
                .tokenHash(UUID.randomUUID().toString())
                .expiresAt(Instant.now().plusMillis(refreshTokenExpirationMs))
                .revoked(false)
                .build();
        refreshTokenRepository.save(refreshToken);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken.getTokenHash())
                .tokenType("Bearer")
                .expiresIn(accessTokenExpirationMs / 1000)
                .user(UserDto.fromEntity(user))
                .build();
    }
}
