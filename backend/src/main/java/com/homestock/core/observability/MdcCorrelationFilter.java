package com.homestock.core.observability;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

/**
 * Filter that attaches a correlation ID and structured metadata to the SLF4J MDC
 * for end-to-end distributed tracing and observability.
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class MdcCorrelationFilter extends OncePerRequestFilter {

    public static final String CORRELATION_ID_HEADER = "X-Correlation-ID";
    public static final String REQUEST_ID_HEADER = "X-Request-ID";
    public static final String MDC_CORRELATION_ID_KEY = "correlationId";
    public static final String MDC_USER_ID_KEY = "userId";
    public static final String MDC_METHOD_KEY = "method";
    public static final String MDC_URI_KEY = "uri";
    public static final String MDC_CLIENT_IP_KEY = "clientIp";

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        long startTime = System.currentTimeMillis();
        String correlationId = resolveCorrelationId(request);
        MDC.put(MDC_CORRELATION_ID_KEY, correlationId);
        MDC.put(MDC_METHOD_KEY, request.getMethod());
        MDC.put(MDC_URI_KEY, request.getRequestURI());
        MDC.put(MDC_CLIENT_IP_KEY, getClientIp(request));

        response.setHeader(CORRELATION_ID_HEADER, correlationId);

        try {
            filterChain.doFilter(request, response);
        } finally {
            // Populate userId if authenticated during request lifecycle
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.getPrincipal() instanceof com.homestock.core.security.UserPrincipal principal) {
                MDC.put(MDC_USER_ID_KEY, principal.getId().toString());
            }

            long durationMs = System.currentTimeMillis() - startTime;
            MDC.put("durationMs", String.valueOf(durationMs));
            MDC.put("status", String.valueOf(response.getStatus()));

            MDC.clear();
        }
    }

    private String resolveCorrelationId(HttpServletRequest request) {
        String correlationId = request.getHeader(CORRELATION_ID_HEADER);
        if (!StringUtils.hasText(correlationId)) {
            correlationId = request.getHeader(REQUEST_ID_HEADER);
        }
        if (!StringUtils.hasText(correlationId)) {
            correlationId = UUID.randomUUID().toString();
        }
        return correlationId;
    }

    private String getClientIp(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (StringUtils.hasText(xForwardedFor)) {
            return xForwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
