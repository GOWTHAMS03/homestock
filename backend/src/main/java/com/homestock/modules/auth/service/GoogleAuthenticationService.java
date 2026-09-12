package com.homestock.modules.auth.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.homestock.core.exception.AccountDisabledException;
import com.homestock.core.exception.BusinessRuleException;
import com.homestock.core.exception.UserNotFoundException;
import com.homestock.modules.auth.dto.GoogleAuthRequest;
import com.homestock.modules.auth.entity.AuthIdentity;
import com.homestock.modules.auth.repository.AuthIdentityRepository;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GoogleAuthenticationService {

    private static final Logger log = LoggerFactory.getLogger(GoogleAuthenticationService.class);

    private final UserRepository userRepository;
    private final AuthIdentityRepository authIdentityRepository;
    private final PasswordEncoder passwordEncoder;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public static class GoogleUserInfo {
        public String sub;
        public String email;
        public String name;
        public String picture;
    }

    @Transactional
    public User authenticateGoogleUser(GoogleAuthRequest request) {
        GoogleUserInfo userInfo = parseGoogleToken(request);

        if (userInfo.sub == null || userInfo.sub.isBlank()) {
            throw new BusinessRuleException("INVALID_GOOGLE_TOKEN", "Google subject identifier (sub) is missing");
        }

        // 1. Check if an AuthIdentity already exists for this Google sub
        Optional<AuthIdentity> existingIdentity = authIdentityRepository
                .findByProviderAndProviderSubject("GOOGLE", userInfo.sub);

        if (existingIdentity.isPresent()) {
            User user = existingIdentity.get().getUser();
            if (user.isDeleted()) {
                throw new UserNotFoundException("This HomeStock account could not be verified. Please sign in again.");
            }
            if (!user.isAccountActive()) {
                throw new AccountDisabledException("This HomeStock account is disabled.");
            }
            user.setLastLoginAt(Instant.now());
            if (userInfo.picture != null && (user.getAvatarUrl() == null || user.getAvatarUrl().isBlank())) {
                user.setAvatarUrl(userInfo.picture);
            }
            return userRepository.save(user);
        }

        // 2. Not found by Google sub: check if an existing user has this verified email
        String email = userInfo.email != null ? userInfo.email.trim().toLowerCase() : null;
        if (email != null && !email.isBlank()) {
            Optional<User> userByEmail = userRepository.findByEmail(email);
            if (userByEmail.isPresent()) {
                User existingUser = userByEmail.get();
                if (existingUser.isDeleted()) {
                    throw new UserNotFoundException("This HomeStock account could not be verified. Please sign in again.");
                }
                if (!existingUser.isAccountActive()) {
                    throw new AccountDisabledException("This HomeStock account is disabled.");
                }

                // Account linking: link Google identity to existing HomeStock account
                AuthIdentity newIdentity = AuthIdentity.builder()
                        .user(existingUser)
                        .provider("GOOGLE")
                        .providerSubject(userInfo.sub)
                        .build();
                authIdentityRepository.save(newIdentity);

                existingUser.setLastLoginAt(Instant.now());
                if (userInfo.picture != null && (existingUser.getAvatarUrl() == null || existingUser.getAvatarUrl().isBlank())) {
                    existingUser.setAvatarUrl(userInfo.picture);
                }
                log.info("Linked Google identity (sub={}) to existing user {}", userInfo.sub, existingUser.getEmail());
                return userRepository.save(existingUser);
            }
        }

        // 3. Brand new user: create permanent HomeStock user and attach Google identity
        String baseName = userInfo.name != null && !userInfo.name.isBlank() ? userInfo.name : "Google User";
        String fallbackEmail = email != null ? email : "google_" + userInfo.sub + "@homestock.user";
        String generatedUsername = generateUniqueUsername(fallbackEmail, baseName);

        User newUser = User.builder()
                .email(fallbackEmail)
                .fullName(baseName)
                .displayName(baseName)
                .username(generatedUsername)
                .avatarUrl(userInfo.picture)
                .passwordHash(passwordEncoder.encode(UUID.randomUUID().toString()))
                .status("ACTIVE")
                .isActive(true)
                .lastLoginAt(Instant.now())
                .build();

        User savedUser = userRepository.save(newUser);

        AuthIdentity newIdentity = AuthIdentity.builder()
                .user(savedUser)
                .provider("GOOGLE")
                .providerSubject(userInfo.sub)
                .build();
        authIdentityRepository.save(newIdentity);

        log.info("Created new HomeStock user with Google identity (sub={})", userInfo.sub);
        return savedUser;
    }

    @Transactional
    public void linkGoogleAccount(UUID userId, GoogleAuthRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        if (user.isDeleted()) {
            throw new UserNotFoundException("This HomeStock account could not be verified.");
        }

        GoogleUserInfo userInfo = parseGoogleToken(request);
        if (userInfo.sub == null || userInfo.sub.isBlank()) {
            throw new BusinessRuleException("INVALID_GOOGLE_TOKEN", "Google sub is required");
        }

        Optional<AuthIdentity> existingIdentity = authIdentityRepository
                .findByProviderAndProviderSubject("GOOGLE", userInfo.sub);

        if (existingIdentity.isPresent()) {
            if (existingIdentity.get().getUser().getId().equals(userId)) {
                return; // already linked to this user
            }
            throw new BusinessRuleException("IDENTITY_ALREADY_LINKED", "This Google account is already linked to another HomeStock user.");
        }

        AuthIdentity identity = AuthIdentity.builder()
                .user(user)
                .provider("GOOGLE")
                .providerSubject(userInfo.sub)
                .build();
        authIdentityRepository.save(identity);
    }

    private GoogleUserInfo parseGoogleToken(GoogleAuthRequest request) {
        GoogleUserInfo info = new GoogleUserInfo();
        info.sub = request.getSub();
        info.email = request.getEmail();
        info.name = request.getDisplayName();
        info.picture = request.getAvatarUrl();

        String token = request.getIdToken();
        if (token != null && token.contains(".")) {
            try {
                String[] parts = token.split("\\.");
                if (parts.length >= 2) {
                    byte[] decoded = Base64.getUrlDecoder().decode(parts[1]);
                    JsonNode claims = objectMapper.readTree(new String(decoded, StandardCharsets.UTF_8));

                    if (claims.has("sub") && (info.sub == null || info.sub.isBlank())) {
                        info.sub = claims.get("sub").asText();
                    }
                    if (claims.has("email") && (info.email == null || info.email.isBlank())) {
                        info.email = claims.get("email").asText();
                    }
                    if (claims.has("name") && (info.name == null || info.name.isBlank())) {
                        info.name = claims.get("name").asText();
                    }
                    if (claims.has("picture") && (info.picture == null || info.picture.isBlank())) {
                        info.picture = claims.get("picture").asText();
                    }
                }
            } catch (Exception e) {
                log.warn("Could not decode Google ID token payload: {}", e.getMessage());
            }
        }

        if ((info.sub == null || info.sub.isBlank()) && token != null && !token.contains(".")) {
            // For dev/test mock tokens, token string itself can serve as the sub
            info.sub = token;
        }

        return info;
    }

    private String generateUniqueUsername(String email, String name) {
        String base = email != null && email.contains("@")
                ? email.split("@")[0].replaceAll("[^a-zA-Z0-9_]", "").toLowerCase()
                : name.replaceAll("[^a-zA-Z0-9_]", "").toLowerCase();
        if (base.isBlank()) base = "user";

        String candidate = base;
        int count = 1;
        while (userRepository.existsByUsername(candidate)) {
            candidate = base + "_" + (count++);
        }
        return candidate;
    }
}
