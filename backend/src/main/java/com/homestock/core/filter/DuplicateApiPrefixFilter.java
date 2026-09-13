package com.homestock.core.filter;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * Filter that transparently normalizes accidental duplicate '/api/v1/api/v1/' path prefixes
 * from legacy or cached mobile client builds down to canonical '/api/v1/'.
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class DuplicateApiPrefixFilter implements Filter {

    private static final String DUPLICATE_PREFIX = "/api/v1/api/v1/";
    private static final String TARGET_PREFIX = "/api/v1/";

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        if (request instanceof HttpServletRequest httpRequest) {
            String uri = httpRequest.getRequestURI();
            if (uri != null && uri.startsWith(DUPLICATE_PREFIX)) {
                String normalized = TARGET_PREFIX + uri.substring(DUPLICATE_PREFIX.length());
                HttpServletRequest wrapped = new HttpServletRequestWrapper(httpRequest) {
                    @Override
                    public String getRequestURI() {
                        return normalized;
                    }

                    @Override
                    public String getServletPath() {
                        return normalized;
                    }
                };
                chain.doFilter(wrapped, response);
                return;
            }
        }
        chain.doFilter(request, response);
    }
}
