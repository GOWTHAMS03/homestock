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
    private final com.homestock.modules.auth.repository.AuthIdentityRepository authIdentityRepository;
    private final GoogleAuthenticationService googleAuthenticationService;
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
        String email = request.getEmail().toLowerCase().trim();
        if (userRepository.existsByEmail(email)) {
            throw new BusinessRuleException("EMAIL_ALREADY_EXISTS", "A user with this email address already exists.");
        }

        if (request.getConfirmPassword() != null && !request.getConfirmPassword().isBlank()
                && !request.getPassword().equals(request.getConfirmPassword())) {
            throw new BusinessRuleException("PASSWORD_MISMATCH", "Password and Confirm Password do not match.");
        }

        String username = request.getUsername();
        if (username != null && !username.isBlank()) {
            username = username.trim().toLowerCase();
            if (userRepository.existsByUsername(username)) {
                throw new BusinessRuleException("USERNAME_ALREADY_EXISTS", "A user with this username already exists.");
            }
        } else {
            String base = email.split("@")[0].replaceAll("[^a-zA-Z0-9_]", "").toLowerCase();
            if (base.isBlank()) base = "user";
            username = base;
            int counter = 1;
            while (userRepository.existsByUsername(username)) {
                username = base + "_" + (counter++);
            }
        }

        User user = User.builder()
                .email(email)
                .username(username)
                .fullName(request.getFullName().trim())
                .displayName(request.getFullName().trim())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .phoneNumber(request.getPhoneNumber())
                .status("ACTIVE")
                .isActive(true)
                .lastLoginAt(Instant.now())
                .build();

        User savedUser = userRepository.save(user);

        // Save local auth identity
        com.homestock.modules.auth.entity.AuthIdentity localIdentity = com.homestock.modules.auth.entity.AuthIdentity.builder()
                .user(savedUser)
                .provider("LOCAL")
                .providerSubject(email)
                .build();
        authIdentityRepository.save(localIdentity);

        return generateAuthResponse(savedUser);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        String identifier = request.getEmail().toLowerCase().trim();
        User user = userRepository.findByIdentifier(identifier)
                .orElseThrow(() -> new org.springframework.security.authentication.BadCredentialsException("Invalid email or password"));

        if (user.isDeleted()) {
            throw new com.homestock.core.exception.UserNotFoundException("This HomeStock account could not be verified. Please sign in again.");
        }

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new org.springframework.security.authentication.BadCredentialsException("Invalid email or password");
        }

        if (!user.isAccountActive()) {
            throw new com.homestock.core.exception.AccountDisabledException("This HomeStock account is disabled.");
        }

        user.setLastLoginAt(Instant.now());
        userRepository.save(user);

        return generateAuthResponse(user);
    }

    @Transactional
    public AuthResponse loginWithGoogle(com.homestock.modules.auth.dto.GoogleAuthRequest request) {
        User user = googleAuthenticationService.authenticateGoogleUser(request);
        return generateAuthResponse(user);
    }

    @Transactional
    public void linkGoogle(UUID currentUserId, com.homestock.modules.auth.dto.GoogleAuthRequest request) {
        googleAuthenticationService.linkGoogleAccount(currentUserId, request);
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
                        String username = candidateEmail.split("@")[0] + "_" + UUID.randomUUID().toString().substring(0, 4);
                        User newUser = userRepository.save(User.builder()
                                .email(candidateEmail)
                                .username(username)
                                .passwordHash(passwordEncoder.encode(rawPassword))
                                .fullName(fullName)
                                .displayName(fullName)
                                .status("ACTIVE")
                                .isActive(true)
                                .lastLoginAt(Instant.now())
                                .build());
                        authIdentityRepository.save(com.homestock.modules.auth.entity.AuthIdentity.builder()
                                .user(newUser)
                                .provider("LOCAL")
                                .providerSubject(candidateEmail)
                                .build());
                        return newUser;
                    });
        } else {
            String rawSanitized = fullName.toLowerCase().replaceAll("[^a-z0-9]", "");
            final String sanitizedName = rawSanitized.isEmpty() ? "member" : rawSanitized;
            final String uniqueEmail = sanitizedName + "." + cleanCode.toLowerCase() + "@homestock.local";

            user = userRepository.findByEmail(uniqueEmail)
                    .orElseGet(() -> {
                        String rawPassword = UUID.randomUUID().toString();
                        String username = sanitizedName + "_" + UUID.randomUUID().toString().substring(0, 4);
                        User newUser = userRepository.save(User.builder()
                                .email(uniqueEmail)
                                .username(username)
                                .passwordHash(passwordEncoder.encode(rawPassword))
                                .fullName(fullName)
                                .displayName(fullName)
                                .status("ACTIVE")
                                .isActive(true)
                                .lastLoginAt(Instant.now())
                                .build());
                        authIdentityRepository.save(com.homestock.modules.auth.entity.AuthIdentity.builder()
                                .user(newUser)
                                .provider("LOCAL")
                                .providerSubject(uniqueEmail)
                                .build());
                        return newUser;
                    });
        }

        if (user.isDeleted()) {
            throw new com.homestock.core.exception.UserNotFoundException("This HomeStock account could not be verified. Please sign in again.");
        }

        if (!user.isAccountActive()) {
            throw new com.homestock.core.exception.AccountDisabledException("This HomeStock account is disabled.");
        }

        // Add user as HomeMember if not already in this household (idempotent)
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
        if (user == null || user.isDeleted()) {
            refreshTokenRepository.delete(refreshToken);
            throw new com.homestock.core.exception.UserNotFoundException("This HomeStock account could not be verified. Please sign in again.");
        }

        if (!user.isAccountActive()) {
            refreshTokenRepository.delete(refreshToken);
            throw new com.homestock.core.exception.AccountDisabledException("This HomeStock account is disabled.");
        }

        // Token rotation: delete old refresh token and issue a fresh pair
        refreshTokenRepository.delete(refreshToken);

        return generateAuthResponse(user);
    }

    @Transactional
    public void logout(String refreshToken) {
        if (refreshToken != null) {
            refreshTokenRepository.findByTokenHash(refreshToken).ifPresent(refreshTokenRepository::delete);
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
