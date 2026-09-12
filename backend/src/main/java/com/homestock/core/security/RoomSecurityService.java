package com.homestock.core.security;

import com.homestock.core.exception.MembershipRemovedException;
import com.homestock.modules.home.entity.RoomMember;
import com.homestock.modules.home.entity.RoomMemberRole;
import com.homestock.modules.home.entity.RoomMemberStatus;
import com.homestock.modules.home.repository.RoomMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.UUID;

@Service("roomSecurity")
@RequiredArgsConstructor
public class RoomSecurityService {

    private final RoomMemberRepository roomMemberRepository;

    public boolean hasPermission(UUID roomId, RoomMemberRole requiredRole) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof UserPrincipal principal)) {
            return false;
        }

        Optional<RoomMember> memberOpt = roomMemberRepository.findByRoomIdAndUserId(roomId, principal.getId());
        if (memberOpt.isEmpty()) {
            return false;
        }

        RoomMember member = memberOpt.get();
        if (member.getStatus() == RoomMemberStatus.REMOVED) {
            throw new MembershipRemovedException("You are no longer an active member of this room.");
        }

        if (member.getStatus() != RoomMemberStatus.ACTIVE) {
            return false;
        }

        return member.getRole().hasPermission(requiredRole);
    }

    public boolean isMember(UUID roomId) {
        return hasPermission(roomId, RoomMemberRole.VIEWER);
    }

    public boolean canManageInventory(UUID roomId) {
        return hasPermission(roomId, RoomMemberRole.MEMBER);
    }

    public boolean canEditShoppingList(UUID roomId) {
        return hasPermission(roomId, RoomMemberRole.MEMBER);
    }

    public boolean canManageMembers(UUID roomId) {
        return hasPermission(roomId, RoomMemberRole.ADMIN);
    }

    public boolean isOwner(UUID roomId) {
        return hasPermission(roomId, RoomMemberRole.OWNER);
    }

    public boolean canRemoveMember(UUID roomId, UUID targetUserId) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof UserPrincipal principal)) {
            return false;
        }
        if (principal.getId().equals(targetUserId)) {
            return isMember(roomId);
        }
        return canManageMembers(roomId);
    }
}
