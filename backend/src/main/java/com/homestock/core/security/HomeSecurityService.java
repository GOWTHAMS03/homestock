package com.homestock.core.security;

import com.homestock.modules.home.entity.HomeMember;
import com.homestock.modules.home.entity.HomeRole;
import com.homestock.modules.home.repository.HomeMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.UUID;

@Service("homeSecurity")
@RequiredArgsConstructor
public class HomeSecurityService {

    private final HomeMemberRepository homeMemberRepository;

    public boolean hasPermission(UUID homeId, HomeRole requiredRole) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof UserPrincipal principal)) {
            return false;
        }

        Optional<HomeMember> memberOpt = homeMemberRepository.findByHomeIdAndUserId(homeId, principal.getId());
        if (memberOpt.isEmpty()) {
            return false;
        }

        HomeMember member = memberOpt.get();
        return member.getRole().hasPermission(requiredRole);
    }

    public boolean isMember(UUID homeId) {
        return hasPermission(homeId, HomeRole.VIEWER);
    }

    public boolean canManageInventory(UUID homeId) {
        return hasPermission(homeId, HomeRole.MEMBER);
    }

    public boolean canManageMembers(UUID homeId) {
        return hasPermission(homeId, HomeRole.ADMIN);
    }

    public boolean isOwner(UUID homeId) {
        return hasPermission(homeId, HomeRole.OWNER);
    }
}
