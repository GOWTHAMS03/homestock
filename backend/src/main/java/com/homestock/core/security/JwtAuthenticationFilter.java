package com.homestock.core.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider tokenProvider;
    private final CustomUserDetailsService customUserDetailsService;
    private final RestAuthenticationEntryPoint authenticationEntryPoint;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String path = request.getRequestURI();
        boolean isPublicPath = path.startsWith("/api/v1/auth/") ||
                path.startsWith("/swagger-ui") ||
                path.startsWith("/v3/api-docs") ||
                path.startsWith("/uploads/");

        try {
            String jwt = getJwtFromRequest(request);

            if (StringUtils.hasText(jwt)) {
                if (tokenProvider.validateToken(jwt)) {
                    UUID userId = tokenProvider.getUserIdFromToken(jwt);
                    UserDetails userDetails = customUserDetailsService.loadUserById(userId);
                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                            userDetails, null, userDetails.getAuthorities());
                    authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            }
        } catch (com.homestock.core.exception.UserNotFoundException ex) {
            logger.warn("Authentication failed - user not found or deleted in DB: " + ex.getMessage());
            request.setAttribute("AUTH_ERROR_CODE", "USER_NOT_FOUND");
            request.setAttribute("AUTH_ERROR_MESSAGE", "This HomeStock account could not be verified. Please sign in again.");
            if (!isPublicPath) {
                authenticationEntryPoint.commence(request, response, null);
                return;
            }
        } catch (com.homestock.core.exception.AccountDisabledException ex) {
            logger.warn("Authentication failed - user account is disabled: " + ex.getMessage());
            request.setAttribute("AUTH_ERROR_CODE", "ACCOUNT_DISABLED");
            request.setAttribute("AUTH_ERROR_MESSAGE", "This HomeStock account is disabled. Please contact support.");
            if (!isPublicPath) {
                authenticationEntryPoint.commence(request, response, null);
                return;
            }
        } catch (io.jsonwebtoken.ExpiredJwtException ex) {
            logger.warn("Authentication failed - JWT expired: " + ex.getMessage());
            request.setAttribute("AUTH_ERROR_CODE", "TOKEN_EXPIRED");
            request.setAttribute("AUTH_ERROR_MESSAGE", "Your session has expired. Please sign in again.");
            if (!isPublicPath) {
                authenticationEntryPoint.commence(request, response, null);
                return;
            }
        } catch (Exception ex) {
            logger.error("Could not set user authentication in security context", ex);
            request.setAttribute("AUTH_ERROR_CODE", "TOKEN_INVALID");
            request.setAttribute("AUTH_ERROR_MESSAGE", "Invalid authentication token.");
            if (!isPublicPath) {
                authenticationEntryPoint.commence(request, response, null);
                return;
            }
        }

        filterChain.doFilter(request, response);
    }

    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}
