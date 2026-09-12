package com.homestock.core.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.homestock.core.exception.ErrorResponse;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.time.Instant;

@Component
public class RestAuthenticationEntryPoint implements AuthenticationEntryPoint {

    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
                         AuthenticationException authException) throws IOException, ServletException {
        String code = (String) request.getAttribute("AUTH_ERROR_CODE");
        String message = (String) request.getAttribute("AUTH_ERROR_MESSAGE");

        if (code == null || code.isBlank()) {
            code = "UNAUTHORIZED";
        }
        if (message == null || message.isBlank()) {
            message = "Authentication is required to access this resource.";
        }

        int status = HttpStatus.UNAUTHORIZED.value();
        if ("ACCOUNT_DISABLED".equals(code)) {
            status = HttpStatus.FORBIDDEN.value();
        }

        ErrorResponse errorResponse = ErrorResponse.builder()
                .timestamp(Instant.now())
                .status(status)
                .code(code)
                .message(message)
                .path(request.getRequestURI())
                .build();

        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setStatus(status);
        objectMapper.writeValue(response.getOutputStream(), errorResponse);
    }
}
