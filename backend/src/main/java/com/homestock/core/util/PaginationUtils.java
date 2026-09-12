package com.homestock.core.util;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;

/**
 * Defensive pagination utility to prevent denial-of-service via unbounded page sizes.
 */
public final class PaginationUtils {

    public static final int DEFAULT_PAGE_SIZE = 20;
    public static final int MAX_PAGE_SIZE = 100;

    private PaginationUtils() {}

    public static int clampPage(int page) {
        return Math.max(page, 0);
    }

    public static int clampSize(int size) {
        if (size <= 0) {
            return DEFAULT_PAGE_SIZE;
        }
        return Math.min(size, MAX_PAGE_SIZE);
    }

    public static Pageable of(int page, int size) {
        return PageRequest.of(clampPage(page), clampSize(size));
    }

    public static Pageable of(int page, int size, Sort sort) {
        return PageRequest.of(clampPage(page), clampSize(size), sort);
    }
}
