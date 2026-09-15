package com.homestock.core.security;

import com.homestock.modules.deals.entity.NearbyShop;
import com.homestock.modules.deals.repository.NearbyShopRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.UUID;

/**
 * Security service for Shop Owner authorization.
 * Used via SpEL: @PreAuthorize("@shopSecurity.isShopOwner(#shopId)")
 */
@Service("shopSecurity")
@RequiredArgsConstructor
public class ShopSecurityService {

    private final NearbyShopRepository nearbyShopRepository;

    /**
     * Check if the authenticated user owns the given shop.
     */
    public boolean isShopOwner(UUID shopId) {
        UserPrincipal principal = getAuthenticatedPrincipal();
        if (principal == null) return false;

        Optional<NearbyShop> shopOpt = nearbyShopRepository.findById(shopId);
        if (shopOpt.isEmpty()) return false;

        NearbyShop shop = shopOpt.get();
        return shop.getOwnerId() != null && shop.getOwnerId().equals(principal.getId());
    }

    /**
     * Check if the authenticated user is a platform admin.
     */
    public boolean isAdmin() {
        UserPrincipal principal = getAuthenticatedPrincipal();
        if (principal == null) return false;
        return principal.getAppRole() == AppRole.ADMIN;
    }

    /**
     * Check if the authenticated user can manage the shop (owner OR admin).
     */
    public boolean canManageShop(UUID shopId) {
        return isShopOwner(shopId) || isAdmin();
    }

    /**
     * Check if the authenticated user has shop owner role at the app level.
     */
    public boolean hasShopOwnerRole() {
        UserPrincipal principal = getAuthenticatedPrincipal();
        if (principal == null) return false;
        return principal.getAppRole().isShopOwner();
    }

    /**
     * Get the authenticated user's ID.
     */
    public UUID getAuthenticatedUserId() {
        UserPrincipal principal = getAuthenticatedPrincipal();
        return principal != null ? principal.getId() : null;
    }

    private UserPrincipal getAuthenticatedPrincipal() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof UserPrincipal principal)) {
            return null;
        }
        return principal;
    }
}
