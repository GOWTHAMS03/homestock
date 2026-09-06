package com.homestock.modules.home.entity;

public enum HomeRole {
    OWNER,
    ADMIN,
    MEMBER,
    VIEWER;

    public boolean canManageHome() {
        return this == OWNER;
    }

    public boolean canManageMembers() {
        return this == OWNER || this == ADMIN;
    }

    public boolean canEditInventory() {
        return this == OWNER || this == ADMIN || this == MEMBER;
    }

    public boolean canEditShoppingList() {
        return this == OWNER || this == ADMIN || this == MEMBER;
    }

    public boolean hasPermission(HomeRole requiredRole) {
        if (this == OWNER) return true;
        if (this == ADMIN && requiredRole != OWNER) return true;
        if (this == MEMBER && (requiredRole == MEMBER || requiredRole == VIEWER)) return true;
        return this == VIEWER && requiredRole == VIEWER;
    }
}
