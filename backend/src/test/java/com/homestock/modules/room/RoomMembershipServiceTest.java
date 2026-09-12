package com.homestock.modules.room;

import com.homestock.core.exception.MembershipRemovedException;
import com.homestock.core.security.RoomSecurityService;
import com.homestock.core.security.UserPrincipal;
import com.homestock.modules.home.dto.CreateRoomRequest;
import com.homestock.modules.home.dto.JoinRoomRequest;
import com.homestock.modules.home.dto.RoomDto;
import com.homestock.modules.home.dto.RoomMemberDto;
import com.homestock.modules.home.entity.RoomMemberRole;
import com.homestock.modules.home.entity.RoomMemberStatus;
import com.homestock.modules.home.repository.RoomMemberRepository;
import com.homestock.modules.home.service.RoomService;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("local")
@Transactional
class RoomMembershipServiceTest {

    @Autowired
    private RoomService roomService;

    @Autowired
    private RoomSecurityService roomSecurityService;

    @Autowired
    private RoomMemberRepository roomMemberRepository;

    @Autowired
    private UserRepository userRepository;

    private User owner;
    private User member;
    private UserPrincipal ownerPrincipal;
    private UserPrincipal memberPrincipal;

    @BeforeEach
    void setUp() {
        owner = new User();
        owner.setEmail("owner@homestock.app");
        owner.setPasswordHash("$2a$10$hash");
        owner.setFullName("Room Owner");
        owner.setStatus("ACTIVE");
        owner = userRepository.save(owner);
        ownerPrincipal = UserPrincipal.create(owner);

        member = new User();
        member.setEmail("member@homestock.app");
        member.setPasswordHash("$2a$10$hash");
        member.setFullName("Room Member");
        member.setStatus("ACTIVE");
        member = userRepository.save(member);
        memberPrincipal = UserPrincipal.create(member);
    }

    private void authenticateAs(UserPrincipal principal) {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities())
        );
    }

    @Test
    void testCreateRoomSetsOwner() {
        authenticateAs(ownerPrincipal);
        CreateRoomRequest req = new CreateRoomRequest();
        req.setName("Family Penthouse");

        RoomDto room = roomService.createRoom(req);
        assertNotNull(room.getId());
        assertEquals("Family Penthouse", room.getName());
        assertEquals(RoomMemberRole.OWNER, room.getCurrentUserRole());
        assertEquals(1, room.getMemberCount());
    }

    @Test
    void testIdempotentJoinProtectsAgainstDoubleClicks() {
        authenticateAs(ownerPrincipal);
        CreateRoomRequest createReq = new CreateRoomRequest();
        createReq.setName("Lake House");
        RoomDto room = roomService.createRoom(createReq);

        authenticateAs(memberPrincipal);
        JoinRoomRequest joinReq = new JoinRoomRequest();
        joinReq.setRoomCode(room.getRoomCode());

        // First join
        RoomDto joined1 = roomService.joinRoom(joinReq);
        assertNotNull(joined1);
        assertEquals(room.getId(), joined1.getId());
        assertEquals(RoomMemberRole.MEMBER, joined1.getCurrentUserRole());

        // Second join (simulate double-click or simultaneous tab)
        // Must succeed idempotently without duplicate key violation or error
        RoomDto joined2 = roomService.joinRoom(joinReq);
        assertNotNull(joined2);
        assertEquals(room.getId(), joined2.getId());
        assertEquals(RoomMemberRole.MEMBER, joined2.getCurrentUserRole());

        authenticateAs(ownerPrincipal);
        List<RoomMemberDto> members = roomService.getRoomMembers(room.getId());
        assertEquals(2, members.size());
    }

    @Test
    void testSoftRemoveMemberAndReactivation() {
        authenticateAs(ownerPrincipal);
        CreateRoomRequest createReq = new CreateRoomRequest();
        createReq.setName("Main Villa");
        RoomDto room = roomService.createRoom(createReq);

        authenticateAs(memberPrincipal);
        JoinRoomRequest joinReq = new JoinRoomRequest();
        joinReq.setRoomCode(room.getRoomCode());
        roomService.joinRoom(joinReq);

        // Remove member
        authenticateAs(ownerPrincipal);
        roomService.removeMember(room.getId(), member.getId());

        // Membership record must still exist in DB for audit trail, but status = REMOVED
        var membershipOpt = roomMemberRepository.findByRoomIdAndUserId(room.getId(), member.getId());
        assertTrue(membershipOpt.isPresent());
        assertEquals(RoomMemberStatus.REMOVED, membershipOpt.get().getStatus());

        // Setup security context as member to test authorization
        authenticateAs(memberPrincipal);

        // Security check must throw MembershipRemovedException
        assertThrows(MembershipRemovedException.class, () -> roomSecurityService.isMember(room.getId()));

        // Rejoining should reactivate membership to ACTIVE
        roomService.joinRoom(joinReq);
        var reactivated = roomMemberRepository.findByRoomIdAndUserId(room.getId(), member.getId());
        assertTrue(reactivated.isPresent());
        assertEquals(RoomMemberStatus.ACTIVE, reactivated.get().getStatus());
    }
}
