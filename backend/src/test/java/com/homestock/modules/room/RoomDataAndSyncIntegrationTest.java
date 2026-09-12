package com.homestock.modules.room;

import com.homestock.core.common.PagedResponse;
import com.homestock.core.exception.MembershipRemovedException;
import com.homestock.core.security.RoomSecurityService;
import com.homestock.core.security.UserPrincipal;
import com.homestock.modules.home.dto.CreateRoomRequest;
import com.homestock.modules.home.dto.JoinRoomRequest;
import com.homestock.modules.home.dto.RoomDto;
import com.homestock.modules.home.service.RoomService;
import com.homestock.modules.inventory.dto.CreateInventoryItemRequest;
import com.homestock.modules.inventory.dto.InventoryItemDto;
import com.homestock.modules.inventory.dto.StockUpdateRequest;
import com.homestock.modules.inventory.entity.TransactionType;
import com.homestock.modules.inventory.service.InventoryService;
import com.homestock.modules.shopping.dto.CreateShoppingItemRequest;
import com.homestock.modules.shopping.dto.ShoppingListDto;
import com.homestock.modules.shopping.service.ShoppingService;
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

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("local")
@Transactional
class RoomDataAndSyncIntegrationTest {

    @Autowired
    private RoomService roomService;

    @Autowired
    private RoomSecurityService roomSecurityService;

    @Autowired
    private InventoryService inventoryService;

    @Autowired
    private ShoppingService shoppingService;

    @Autowired
    private UserRepository userRepository;

    private User userA;
    private User userB;
    private UserPrincipal principalA;
    private UserPrincipal principalB;
    private RoomDto room;

    @BeforeEach
    void setUp() {
        userA = new User();
        userA.setEmail("usera@homestock.app");
        userA.setPasswordHash("$2a$10$hash");
        userA.setFullName("User Alpha");
        userA.setStatus("ACTIVE");
        userA = userRepository.save(userA);
        principalA = UserPrincipal.create(userA);

        userB = new User();
        userB.setEmail("userb@homestock.app");
        userB.setPasswordHash("$2a$10$hash");
        userB.setFullName("User Beta");
        userB.setStatus("ACTIVE");
        userB = userRepository.save(userB);
        principalB = UserPrincipal.create(userB);

        authenticateAs(principalA);
        CreateRoomRequest roomReq = new CreateRoomRequest();
        roomReq.setName("Shared Alpha-Beta Household");
        room = roomService.createRoom(roomReq);

        authenticateAs(principalB);
        JoinRoomRequest joinReq = new JoinRoomRequest();
        joinReq.setRoomCode(room.getRoomCode());
        roomService.joinRoom(joinReq);
    }

    private void authenticateAs(UserPrincipal principal) {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities())
        );
    }

    @Test
    void testSharedHouseholdDataBetweenRoomMembers() {
        authenticateAs(principalA);

        // User A creates inventory item in shared room
        CreateInventoryItemRequest itemReq = new CreateInventoryItemRequest();
        itemReq.setName("Organic Olive Oil");
        itemReq.setQuantity(new BigDecimal("2.0"));
        itemReq.setUnit("bottle");
        InventoryItemDto createdItem = inventoryService.createItem(room.getId(), itemReq);
        assertNotNull(createdItem.getId());

        // Switch security context to User B
        authenticateAs(principalB);

        // User B views inventory in the room
        PagedResponse<InventoryItemDto> items = inventoryService.getItems(room.getId(), null, null, null, 0, 20);
        assertEquals(1, items.getContent().size());
        assertEquals("Organic Olive Oil", items.getContent().get(0).getName());

        // User B updates stock in the room
        StockUpdateRequest updateReq = new StockUpdateRequest();
        updateReq.setTransactionType(TransactionType.ADJUSTMENT);
        updateReq.setQuantityChange(new BigDecimal("1.0"));
        InventoryItemDto updatedItem = inventoryService.updateStock(room.getId(), createdItem.getId(), updateReq);
        assertEquals(new BigDecimal("1.0"), updatedItem.getQuantity());

        // User B adds item to shared shopping list
        ShoppingListDto list = shoppingService.getDefaultShoppingList(room.getId());
        CreateShoppingItemRequest shopReq = new CreateShoppingItemRequest();
        shopReq.setItemName("Sourdough Bread");
        shopReq.setQuantity(new BigDecimal("1.0"));
        shopReq.setUnit("loaf");
        shoppingService.addItem(room.getId(), list.getId(), shopReq);

        // Switch back to User A
        authenticateAs(principalA);
        ShoppingListDto shoppingList = shoppingService.getDefaultShoppingList(room.getId());
        assertNotNull(shoppingList);
        assertTrue(shoppingList.getItems().stream().anyMatch(i -> "Sourdough Bread".equals(i.getItemName())));
    }

    @Test
    void testMemberRemovedWhileOfflineCannotAccessRoomData() {
        authenticateAs(principalA);

        // Remove User B from room
        roomService.removeMember(room.getId(), userB.getId());

        // User B tries to access room data
        authenticateAs(principalB);

        // roomSecurity.isMember throws MembershipRemovedException
        assertThrows(MembershipRemovedException.class, () -> roomSecurityService.isMember(room.getId()));
    }
}
