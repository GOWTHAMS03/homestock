package com.homestock.modules.home.service;

import com.homestock.core.exception.BusinessRuleException;
import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.core.util.SecurityUtils;
import com.homestock.modules.category.service.CategoryService;
import com.homestock.modules.home.dto.*;
import com.homestock.modules.home.entity.*;
import com.homestock.modules.home.repository.HomeMemberRepository;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.home.repository.RoomMemberRepository;
import com.homestock.modules.home.repository.RoomRepository;
import com.homestock.modules.sync.service.HomeChangeLogService;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RoomService {

    private static final Logger log = LoggerFactory.getLogger(RoomService.class);

    private final RoomRepository roomRepository;
    private final RoomMemberRepository roomMemberRepository;
    private final HomeRepository homeRepository;
    private final HomeMemberRepository homeMemberRepository;
    private final UserRepository userRepository;
    private final CategoryService categoryService;
    private final HomeChangeLogService homeChangeLogService;

    private static final String CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private final SecureRandom random = new SecureRandom();

    @Transactional
    public RoomDto createRoom(CreateRoomRequest request) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new com.homestock.core.exception.UserNotFoundException("User not found"));

        if (currentUser.isDeleted()) {
            throw new com.homestock.core.exception.UserNotFoundException("This HomeStock account could not be verified.");
        }

        String roomCode = generateUniqueRoomCode();

        Room room = Room.builder()
                .name(request.getName().trim())
                .roomCode(roomCode)
                .owner(currentUser)
                .status("ACTIVE")
                .build();

        Room savedRoom = roomRepository.save(room);

        RoomMember ownerMember = RoomMember.builder()
                .room(savedRoom)
                .user(currentUser)
                .role(RoomMemberRole.OWNER)
                .status(RoomMemberStatus.ACTIVE)
                .joinedAt(Instant.now())
                .build();
        roomMemberRepository.save(ownerMember);

        // Synchronize with homes table for backward compatibility
        syncToHome(savedRoom, currentUser, HomeRole.OWNER);

        return RoomDto.fromEntity(savedRoom, RoomMemberRole.OWNER, 1);
    }

    @Transactional
    public RoomDto joinRoom(JoinRoomRequest request) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new com.homestock.core.exception.UserNotFoundException("User not found"));

        if (currentUser.isDeleted()) {
            throw new com.homestock.core.exception.UserNotFoundException("This HomeStock account could not be verified.");
        }

        String code = request.getRoomCode().trim().toUpperCase();
        Room room = roomRepository.findByRoomCode(code)
                .orElseGet(() -> {
                    // Fallback to homes table if not yet synced
                    Home h = homeRepository.findByInviteCode(code)
                            .orElseThrow(() -> new ResourceNotFoundException("Invalid room code: " + code));
                    return syncFromHome(h);
                });

        if (!"ACTIVE".equalsIgnoreCase(room.getStatus())) {
            throw new BusinessRuleException("ROOM_INACTIVE", "This household room is no longer active.");
        }

        // Check for existing membership (Idempotency / Double-join protection)
        Optional<RoomMember> existingOpt = roomMemberRepository.findByRoomIdAndUserId(room.getId(), currentUserId);
        RoomMember member;
        if (existingOpt.isPresent()) {
            member = existingOpt.get();
            if (member.getStatus() == RoomMemberStatus.REMOVED) {
                // Restore membership
                member.setStatus(RoomMemberStatus.ACTIVE);
                member.setJoinedAt(Instant.now());
                member = roomMemberRepository.save(member);
                log.info("Restored room membership for user {} in room {}", currentUserId, room.getId());
            } else {
                log.info("User {} already an active member of room {} - returning existing membership", currentUserId, room.getId());
            }
        } else {
            try {
                member = RoomMember.builder()
                        .room(room)
                        .user(currentUser)
                        .role(RoomMemberRole.MEMBER)
                        .status(RoomMemberStatus.ACTIVE)
                        .joinedAt(Instant.now())
                        .build();
                member = roomMemberRepository.save(member);
            } catch (Exception ex) {
                // Fallback on race condition: fetch the row created by concurrent request
                member = roomMemberRepository.findByRoomIdAndUserId(room.getId(), currentUserId)
                        .orElseThrow(() -> new BusinessRuleException("JOIN_ERROR", "Could not complete join"));
            }
        }

        // Mirror to home_members
        syncMemberToHome(room.getId(), currentUser, HomeRole.MEMBER);

        int memberCount = roomMemberRepository.findByRoomIdAndStatus(room.getId(), RoomMemberStatus.ACTIVE).size();
        return RoomDto.fromEntity(room, member.getRole(), memberCount);
    }

    @Transactional(readOnly = true)
    public List<RoomDto> getCurrentUserRooms() {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        List<RoomMember> memberships = roomMemberRepository.findByUserIdAndStatus(currentUserId, RoomMemberStatus.ACTIVE);

        return memberships.stream()
                .filter(m -> "ACTIVE".equalsIgnoreCase(m.getRoom().getStatus()))
                .map(m -> {
                    int count = roomMemberRepository.findByRoomIdAndStatus(m.getRoom().getId(), RoomMemberStatus.ACTIVE).size();
                    return RoomDto.fromEntity(m.getRoom(), m.getRole(), count);
                })
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public RoomDto getRoomById(UUID roomId) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResourceNotFoundException("Room not found with ID: " + roomId));

        RoomMember member = roomMemberRepository.findByRoomIdAndUserId(roomId, currentUserId)
                .orElseThrow(() -> new BusinessRuleException("ROOM_ACCESS_DENIED", "You are not a member of this room"));

        if (member.getStatus() != RoomMemberStatus.ACTIVE) {
            throw new com.homestock.core.exception.MembershipRemovedException("You are no longer an active member of this room.");
        }

        int count = roomMemberRepository.findByRoomIdAndStatus(roomId, RoomMemberStatus.ACTIVE).size();
        return RoomDto.fromEntity(room, member.getRole(), count);
    }

    @Transactional(readOnly = true)
    public List<RoomMemberDto> getRoomMembers(UUID roomId) {
        return roomMemberRepository.findByRoomIdAndStatus(roomId, RoomMemberStatus.ACTIVE)
                .stream()
                .map(RoomMemberDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public void removeMember(UUID roomId, UUID targetUserId) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResourceNotFoundException("Room not found with ID: " + roomId));

        RoomMember currentMember = roomMemberRepository.findByRoomIdAndUserId(roomId, currentUserId)
                .orElseThrow(() -> new BusinessRuleException("ROOM_ACCESS_DENIED", "You are not a member of this room"));

        boolean isSelf = currentUserId.equals(targetUserId);
        boolean isOwnerOrAdmin = currentMember.getRole() == RoomMemberRole.OWNER || currentMember.getRole() == RoomMemberRole.ADMIN;

        if (!isSelf && !isOwnerOrAdmin) {
            throw new BusinessRuleException("FORBIDDEN", "Only OWNER or ADMIN can remove other members");
        }

        RoomMember targetMember = roomMemberRepository.findByRoomIdAndUserId(roomId, targetUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Member not found in this room"));

        if (targetMember.getRole() == RoomMemberRole.OWNER && !isSelf) {
            throw new BusinessRuleException("CANNOT_REMOVE_OWNER", "The room owner cannot be removed");
        }

        // Soft deletion of membership
        targetMember.setStatus(RoomMemberStatus.REMOVED);
        targetMember.setUpdatedAt(Instant.now());
        roomMemberRepository.save(targetMember);

        // Also remove from home_members
        homeMemberRepository.findByHomeIdAndUserId(roomId, targetUserId)
                .ifPresent(homeMemberRepository::delete);

        // Record change log for sync engine
        homeRepository.findById(roomId).ifPresent(h ->
                homeChangeLogService.recordChange(h, "HOME_MEMBER", targetMember.getId(), "DELETE", null, null)
        );
    }

    private String generateUniqueRoomCode() {
        String code;
        do {
            StringBuilder sb = new StringBuilder(8);
            for (int i = 0; i < 8; i++) {
                sb.append(CODE_CHARS.charAt(random.nextInt(CODE_CHARS.length())));
            }
            code = sb.toString();
        } while (roomRepository.existsByRoomCode(code) || homeRepository.existsByInviteCode(code));
        return code;
    }

    private void syncToHome(Room room, User owner, HomeRole role) {
        if (!homeRepository.existsById(room.getId())) {
            Home home = Home.builder()
                    .name(room.getName())
                    .inviteCode(room.getRoomCode())
                    .createdBy(owner)
                    .build();
            home.setId(room.getId());
            Home savedHome = homeRepository.save(home);

            HomeMember homeMember = HomeMember.builder()
                    .home(savedHome)
                    .user(owner)
                    .role(role)
                    .joinedAt(Instant.now())
                    .build();
            homeMemberRepository.save(homeMember);

            categoryService.seedDefaultCategoriesForHome(savedHome);
            homeChangeLogService.recordChange(savedHome, "HOME", savedHome.getId(), "INSERT", null, null);
        }
    }

    private void syncMemberToHome(UUID roomId, User user, HomeRole role) {
        if (!homeMemberRepository.existsByHomeIdAndUserId(roomId, user.getId())) {
            homeRepository.findById(roomId).ifPresent(home -> {
                HomeMember hm = HomeMember.builder()
                        .home(home)
                        .user(user)
                        .role(role)
                        .joinedAt(Instant.now())
                        .build();
                HomeMember savedHm = homeMemberRepository.save(hm);
                homeChangeLogService.recordChange(home, "HOME_MEMBER", savedHm.getId(), "INSERT", null, null);
            });
        }
    }

    private Room syncFromHome(Home home) {
        Room r = Room.builder()
                .name(home.getName())
                .roomCode(home.getInviteCode())
                .owner(home.getCreatedBy())
                .status("ACTIVE")
                .build();
        r.setId(home.getId());
        return roomRepository.save(r);
    }
}
