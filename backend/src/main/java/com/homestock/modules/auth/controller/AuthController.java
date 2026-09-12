package com.homestock.modules.auth.controller;

import com.homestock.core.common.ApiResponse;
import com.homestock.modules.auth.dto.AuthResponse;
import com.homestock.modules.auth.dto.LoginRequest;
import com.homestock.modules.auth.dto.RefreshTokenRequest;
import com.homestock.modules.auth.dto.RegisterRequest;
import com.homestock.modules.auth.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication", description = "Endpoints for user registration, login, token refresh, and logout")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    @com.homestock.core.redis.RateLimited(keyPrefix = "auth_register", limit = 15, windowSeconds = 60)
    @Operation(summary = "Register a new user account")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest request) {
        AuthResponse response = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("User registered successfully", response));
    }

    @PostMapping("/login")
    @com.homestock.core.redis.RateLimited(keyPrefix = "auth_login", limit = 15, windowSeconds = 60)
    @Operation(summary = "Login with email or username and password")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(ApiResponse.success("Login successful", response));
    }

    @PostMapping("/google")
    @com.homestock.core.redis.RateLimited(keyPrefix = "auth_google", limit = 15, windowSeconds = 60)
    @Operation(summary = "Sign in or register using Google credentials")
    public ResponseEntity<ApiResponse<AuthResponse>> loginWithGoogle(@Valid @RequestBody com.homestock.modules.auth.dto.GoogleAuthRequest request) {
        AuthResponse response = authService.loginWithGoogle(request);
        return ResponseEntity.ok(ApiResponse.success("Google authentication successful", response));
    }

    @PostMapping("/link-google")
    @Operation(summary = "Link Google identity to current authenticated HomeStock user")
    public ResponseEntity<ApiResponse<Void>> linkGoogle(
            @org.springframework.security.core.annotation.AuthenticationPrincipal com.homestock.core.security.UserPrincipal principal,
            @Valid @RequestBody com.homestock.modules.auth.dto.GoogleAuthRequest request) {
        if (principal == null) {
            throw new com.homestock.core.exception.UnauthorizedException("Authentication required to link account");
        }
        authService.linkGoogle(principal.getId(), request);
        return ResponseEntity.ok(ApiResponse.success("Google account linked successfully", null));
    }

    @PostMapping("/invite-login")
    @Operation(summary = "Join or log in to a household using an invite code and name")
    public ResponseEntity<ApiResponse<AuthResponse>> loginWithInviteCode(@Valid @RequestBody com.homestock.modules.auth.dto.InviteLoginRequest request) {
        AuthResponse response = authService.loginWithInviteCode(request);
        return ResponseEntity.ok(ApiResponse.success("Joined household successfully", response));
    }

    @PostMapping("/refresh")
    @Operation(summary = "Refresh access token using refresh token")
    public ResponseEntity<ApiResponse<AuthResponse>> refreshToken(@Valid @RequestBody RefreshTokenRequest request) {
        AuthResponse response = authService.refreshToken(request);
        return ResponseEntity.ok(ApiResponse.success("Token refreshed", response));
    }

    @PostMapping("/logout")
    @Operation(summary = "Logout and revoke refresh token")
    public ResponseEntity<ApiResponse<Void>> logout(@RequestBody(required = false) RefreshTokenRequest request) {
        if (request != null) {
            authService.logout(request.getRefreshToken());
        }
        return ResponseEntity.ok(ApiResponse.success("Logged out successfully", null));
    }

    @GetMapping("/ping")
    @Operation(summary = "Fast server reachability check")
    public ResponseEntity<ApiResponse<String>> ping() {
        return ResponseEntity.ok(ApiResponse.success("pong", "pong"));
    }
}

