package com.homestock.modules.home.entity;

public enum RoomMemberRole {
    OWNER,
    ADMIN,
    MEMBER,
    VIEWER;

    public boolean canManageRoom() {
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

    public boolean hasPermission(RoomMemberRole requiredRole) {
        if (this == OWNER) return true;
        if (this == ADMIN && requiredRole != OWNER) return true;
        if (this == MEMBER && (requiredRole == MEMBER || requiredRole == VIEWER)) return true;
        return this == VIEWER && requiredRole == VIEWER;
    }
}
