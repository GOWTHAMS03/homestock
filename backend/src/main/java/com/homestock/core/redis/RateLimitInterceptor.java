package com.homestock.core.redis;

import com.homestock.core.exception.RateLimitExceededException;
import com.homestock.core.util.SecurityUtils;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.UUID;

/**
 * Spring MVC Interceptor that inspects controller methods for the @RateLimited annotation
 * and enforces Redis-based rate limiting per user or per client IP.
 */
@Component
@RequiredArgsConstructor
public class RateLimitInterceptor implements HandlerInterceptor {

    private final RateLimitingService rateLimitingService;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        if (!(handler instanceof HandlerMethod handlerMethod)) {
            return true;
        }

        RateLimited annotation = handlerMethod.getMethodAnnotation(RateLimited.class);
        if (annotation == null) {
            annotation = handlerMethod.getBeanType().getAnnotation(RateLimited.class);
        }

        if (annotation == null) {
            return true;
        }

        String clientIdentifier = resolveClientIdentifier(request);
        boolean allowed = rateLimitingService.isAllowed(
                annotation.keyPrefix(),
                clientIdentifier,
                annotation.limit(),
                annotation.windowSeconds()
        );

        if (!allowed) {
            throw new RateLimitExceededException(
                    annotation.keyPrefix(),
                    annotation.limit(),
                    annotation.windowSeconds()
            );
        }

        return true;
    }

    private String resolveClientIdentifier(HttpServletRequest request) {
        try {
            UUID userId = SecurityUtils.getCurrentUserId();
            if (userId != null) {
                return "user:" + userId;
            }
        } catch (Exception ignored) {
            // Unauthenticated request, fall through to IP resolution
        }

        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isBlank()) {
            return "ip:" + xForwardedFor.split(",")[0].trim();
        }

        String remoteAddr = request.getRemoteAddr();
        return "ip:" + (remoteAddr != null ? remoteAddr : "unknown");
    }
}
