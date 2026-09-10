package com.homestock.modules.home.service;

import com.homestock.core.exception.BusinessRuleException;
import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.core.util.SecurityUtils;
import com.homestock.modules.category.service.CategoryService;
import com.homestock.modules.home.dto.*;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.entity.HomeMember;
import com.homestock.modules.home.entity.HomeRole;
import com.homestock.modules.home.repository.HomeMemberRepository;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class HomeService {

    private final HomeRepository homeRepository;
    private final HomeMemberRepository homeMemberRepository;
    private final UserRepository userRepository;
    private final CategoryService categoryService;
    private final com.homestock.modules.sync.service.HomeChangeLogService homeChangeLogService;
    private final com.homestock.modules.notification.service.NotificationEngine notificationEngine;

    private static final String CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private final SecureRandom random = new SecureRandom();

    @Transactional
    public HomeDto createHome(CreateHomeRequest request) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        String inviteCode = generateUniqueInviteCode();

        Home home = Home.builder()
                .name(request.getName().trim())
                .inviteCode(inviteCode)
                .createdBy(currentUser)
                .build();

        Home savedHome = homeRepository.save(home);

        HomeMember ownerMember = HomeMember.builder()
                .home(savedHome)
                .user(currentUser)
                .role(HomeRole.OWNER)
                .build();
        HomeMember savedOwner = homeMemberRepository.save(ownerMember);

        // Seed default household categories
        categoryService.seedDefaultCategoriesForHome(savedHome);

        // Record change log for sync
        homeChangeLogService.recordChange(savedHome, "HOME", savedHome.getId(), "INSERT", null, null);
        homeChangeLogService.recordChange(savedHome, "HOME_MEMBER", savedOwner.getId(), "INSERT", null, null);

        return HomeDto.fromEntity(savedHome, HomeRole.OWNER, 1);
    }

    @Transactional
    public HomeDto joinHome(JoinHomeRequest request) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        String code = request.getInviteCode().trim().toUpperCase();
        Home home = homeRepository.findByInviteCode(code)
                .orElseThrow(() -> new ResourceNotFoundException("Invalid home invite code"));

        if (homeMemberRepository.existsByHomeIdAndUserId(home.getId(), currentUserId)) {
            throw new BusinessRuleException("You are already a member of this home.");
        }

        HomeMember newMember = HomeMember.builder()
                .home(home)
                .user(currentUser)
                .role(HomeRole.MEMBER)
                .build();
        HomeMember savedMember = homeMemberRepository.save(newMember);

        // Record change log & notify family members
        homeChangeLogService.recordChange(home, "HOME_MEMBER", savedMember.getId(), "INSERT", null, null);
        notificationEngine.notifyHomeChanged(home, currentUserId);

        int memberCount = homeMemberRepository.findAllByHomeId(home.getId()).size();
        return HomeDto.fromEntity(home, HomeRole.MEMBER, memberCount);
    }

    @Transactional(readOnly = true)
    public List<HomeDto> getCurrentUserHomes() {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        List<HomeMember> memberships = homeMemberRepository.findAllByUserId(currentUserId);

        return memberships.stream().map(membership -> {
            Home home = membership.getHome();
            int memberCount = homeMemberRepository.findAllByHomeId(home.getId()).size();
            return HomeDto.fromEntity(home, membership.getRole(), memberCount);
        }).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public HomeDto getHomeById(UUID homeId) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        HomeMember membership = homeMemberRepository.findByHomeIdAndUserId(homeId, currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Home not found or access denied"));

        Home home = membership.getHome();
        int memberCount = homeMemberRepository.findAllByHomeId(homeId).size();
        return HomeDto.fromEntity(home, membership.getRole(), memberCount);
    }

    @Transactional
    public HomeDto updateHome(UUID homeId, UpdateHomeRequest request) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        HomeMember membership = homeMemberRepository.findByHomeIdAndUserId(homeId, currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Home not found or access denied"));

        if (!membership.getRole().canManageHome() && membership.getRole() != HomeRole.ADMIN) {
            throw new BusinessRuleException("Only OWNER or ADMIN can update home details");
        }

        Home home = membership.getHome();
        home.setName(request.getName().trim());
        Home updatedHome = homeRepository.save(home);

        // Record change log & notify family members
        homeChangeLogService.recordChange(updatedHome, "HOME", updatedHome.getId(), "UPDATE", null, null);
        notificationEngine.notifyHomeChanged(updatedHome, currentUserId);

        int memberCount = homeMemberRepository.findAllByHomeId(homeId).size();
        return HomeDto.fromEntity(updatedHome, membership.getRole(), memberCount);
    }

    @Transactional(readOnly = true)
    public List<HomeMemberDto> getHomeMembers(UUID homeId) {
        return homeMemberRepository.findAllByHomeId(homeId).stream()
                .map(HomeMemberDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public HomeMemberDto updateMemberRole(UUID homeId, UUID targetUserId, UpdateMemberRoleRequest request) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        HomeMember currentMember = homeMemberRepository.findByHomeIdAndUserId(homeId, currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Access denied"));

        if (currentMember.getRole() != HomeRole.OWNER) {
            throw new BusinessRuleException("Only the home OWNER can modify member roles");
        }

        HomeMember targetMember = homeMemberRepository.findByHomeIdAndUserId(homeId, targetUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Target member not found in this home"));

        if (targetMember.getRole() == HomeRole.OWNER && request.getRole() != HomeRole.OWNER) {
            throw new BusinessRuleException("Cannot demote OWNER. Transfer ownership first.");
        }

        targetMember.setRole(request.getRole());
        HomeMember updated = homeMemberRepository.save(targetMember);

        // Record change log & notify family members
        homeChangeLogService.recordChange(currentMember.getHome(), "HOME_MEMBER", updated.getId(), "UPDATE", null, null);
        notificationEngine.notifyHomeChanged(currentMember.getHome(), currentUserId);

        return HomeMemberDto.fromEntity(updated);
    }

    @Transactional
    public void removeMember(UUID homeId, UUID targetUserId) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        HomeMember currentMember = homeMemberRepository.findByHomeIdAndUserId(homeId, currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Access denied"));

        HomeMember targetMember = homeMemberRepository.findByHomeIdAndUserId(homeId, targetUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Member not found in this home"));

        // A user can leave, or an OWNER/ADMIN can remove a member
        boolean isSelf = currentUserId.equals(targetUserId);
        boolean canManage = currentMember.getRole().canManageMembers();

        if (!isSelf && !canManage) {
            throw new BusinessRuleException("You do not have permission to remove this member");
        }

        if (targetMember.getRole() == HomeRole.OWNER) {
            throw new BusinessRuleException("The OWNER cannot be removed. Transfer ownership or delete the home.");
        }

        Home memberHome = targetMember.getHome();
        homeMemberRepository.delete(targetMember);

        // Record change log with the targetUserId so clients remove from local DB & notify family members
        homeChangeLogService.recordChange(memberHome, "HOME_MEMBER", targetUserId, "DELETE", null, null);
        notificationEngine.notifyHomeChanged(memberHome, currentUserId);
    }

    private String generateUniqueInviteCode() {
        String code;
        do {
            StringBuilder sb = new StringBuilder(8);
            for (int i = 0; i < 8; i++) {
                sb.append(CODE_CHARS.charAt(random.nextInt(CODE_CHARS.length())));
            }
            code = sb.toString();
        } while (homeRepository.existsByInviteCode(code));
        return code;
    }
}
