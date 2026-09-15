package com.homestock.core.security;

/**
 * Application-level role for global feature access.
 * Orthogonal to {@link com.homestock.modules.home.entity.HomeRole} which governs per-household RBAC.
 */
public enum AppRole {
    USER,
    SHOP_OWNER,
    ADMIN;

    public boolean isShopOwner() {
        return this == SHOP_OWNER || this == ADMIN;
    }

    public boolean isAdmin() {
        return this == ADMIN;
    }

    public String toAuthority() {
        return "ROLE_" + this.name();
    }
}
