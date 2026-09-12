package com.homestock;

import com.homestock.core.exception.BusinessRuleException;
import com.homestock.core.security.UserPrincipal;
import com.homestock.core.storage.LocalStorageService;
import com.homestock.core.util.PaginationUtils;
import com.homestock.modules.auth.dto.AuthResponse;
import com.homestock.modules.auth.dto.RegisterRequest;
import com.homestock.modules.auth.service.AuthService;
import com.homestock.modules.home.dto.CreateHomeRequest;
import com.homestock.modules.home.dto.CreateRoomRequest;
import com.homestock.modules.home.dto.HomeDto;
import com.homestock.modules.home.dto.RoomDto;
import com.homestock.modules.home.service.HomeService;
import com.homestock.modules.home.service.RoomService;
import com.homestock.modules.shopping.dto.ShoppingListDto;
import com.homestock.modules.shopping.service.ShoppingService;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("local")
@Transactional
public class SecurityHardeningIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private HomeService homeService;

    @Autowired
    private RoomService roomService;

    @Autowired
    private ShoppingService shoppingService;

    @Autowired
    private LocalStorageService localStorageService;

    private User userA;
    private User userB;
    private String tokenA;
    private String tokenB;
    private HomeDto homeA;
    private ShoppingListDto shoppingListA;

    @BeforeEach
    void setUp() {
        // Register User A
        RegisterRequest regA = new RegisterRequest();
        regA.setEmail("usera_" + UUID.randomUUID() + "@example.com");
        regA.setPassword("Password123!");
        regA.setFullName("User Alpha");
        AuthResponse authA = authService.register(regA);
        tokenA = authA.getAccessToken();
        userA = userRepository.findById(authA.getUser().getId()).orElseThrow();

        // Register User B
        RegisterRequest regB = new RegisterRequest();
        regB.setEmail("userb_" + UUID.randomUUID() + "@example.com");
        regB.setPassword("Password123!");
        regB.setFullName("User Beta");
        AuthResponse authB = authService.register(regB);
        tokenB = authB.getAccessToken();
        userB = userRepository.findById(authB.getUser().getId()).orElseThrow();

        // Authenticate as User A and create Home A
        setAuthenticatedUser(userA);
        CreateHomeRequest homeReq = new CreateHomeRequest();
        homeReq.setName("Alpha Household");
        homeA = homeService.createHome(homeReq);
        shoppingListA = shoppingService.getDefaultShoppingList(homeA.getId());
    }

    private void setAuthenticatedUser(User user) {
        UserPrincipal principal = UserPrincipal.create(user);
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    void testDealEngine_ShoppingListIdorPrevention() throws Exception {
        // User B attempts to access deals for User A's private household shopping list
        mockMvc.perform(get("/api/v1/deals/shopping-list/" + shoppingListA.getId())
                        .header("Authorization", "Bearer " + tokenB)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden());

        // User A (member of Home A) successfully accesses the shopping list deals
        mockMvc.perform(get("/api/v1/deals/shopping-list/" + shoppingListA.getId())
                        .header("Authorization", "Bearer " + tokenA)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk());
    }

    @Test
    void testNotificationML_HouseholdPredictionsIdorPrevention() throws Exception {
        // User B attempts to access ML predictions for Home A
        mockMvc.perform(get("/api/v1/notifications/ml/predictions/" + homeA.getId())
                        .header("Authorization", "Bearer " + tokenB)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden());

        // User A successfully accesses ML predictions for Home A
        mockMvc.perform(get("/api/v1/notifications/ml/predictions/" + homeA.getId())
                        .header("Authorization", "Bearer " + tokenA)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk());
    }

    @Test
    void testNotification_InsightsCrossHouseholdPrevention() throws Exception {
        // User B attempts to query insights for Home A
        mockMvc.perform(get("/api/v1/notifications/insights")
                        .param("homeId", homeA.getId().toString())
                        .header("Authorization", "Bearer " + tokenB)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden());

        // User A queries insights for Home A
        mockMvc.perform(get("/api/v1/notifications/insights")
                        .param("homeId", homeA.getId().toString())
                        .header("Authorization", "Bearer " + tokenA)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk());
    }

    @Test
    void testRoomMember_RemovalAuthorization() {
        setAuthenticatedUser(userA);
        CreateRoomRequest roomReq = new CreateRoomRequest();
        roomReq.setName("Living Room");
        RoomDto room = roomService.createRoom(roomReq);

        // User B is not admin in the room and cannot kick User A
        setAuthenticatedUser(userB);
        assertThrows(BusinessRuleException.class, () ->
                roomService.removeMember(room.getId(), userA.getId())
        );
    }

    @Test
    void testFileUpload_MaliciousTypesAndPathTraversalRejected() {
        // 1. Executable upload attempt
        MockMultipartFile exeFile = new MockMultipartFile(
                "file", "malicious.exe", "application/x-msdownload", "MALICIOUS_BYTES".getBytes()
        );
        assertThrows(BusinessRuleException.class, () ->
                localStorageService.storeFile(exeFile, "items")
        );

        // 2. HTML upload attempt (Stored XSS)
        MockMultipartFile htmlFile = new MockMultipartFile(
                "file", "xss.html", "text/html", "<script>alert(1)</script>".getBytes()
        );
        assertThrows(BusinessRuleException.class, () ->
                localStorageService.storeFile(htmlFile, "items")
        );

        // 3. Path traversal filename attempt
        MockMultipartFile pathTraversalFile = new MockMultipartFile(
                "file", "../../etc/passwd.png", "image/png", new byte[]{ (byte) 0x89, 'P', 'N', 'G' }
        );
        assertThrows(BusinessRuleException.class, () ->
                localStorageService.storeFile(pathTraversalFile, "items")
        );

        // 4. Valid PNG image
        MockMultipartFile validImage = new MockMultipartFile(
                "file", "apple.png", "image/png", new byte[]{ (byte) 0x89, 'P', 'N', 'G' }
        );
        String url = localStorageService.storeFile(validImage, "items");
        assertNotNull(url);
        assertTrue(url.startsWith("/uploads/items/"));
        assertTrue(url.endsWith(".png"));
    }

    @Test
    void testFileUpload_OversizedFileRejected() {
        byte[] largeBytes = new byte[(int) (LocalStorageService.MAX_FILE_SIZE_BYTES + 1024)];
        MockMultipartFile largeFile = new MockMultipartFile(
                "file", "large.png", "image/png", largeBytes
        );
        assertThrows(BusinessRuleException.class, () ->
                localStorageService.storeFile(largeFile, "items")
        );
    }

    @Test
    void testPaginationUtils_Clamping() {
        assertEquals(100, PaginationUtils.clampSize(500000));
        assertEquals(PaginationUtils.DEFAULT_PAGE_SIZE, PaginationUtils.clampSize(0));
        assertEquals(PaginationUtils.DEFAULT_PAGE_SIZE, PaginationUtils.clampSize(-10));
        assertEquals(50, PaginationUtils.clampSize(50));
        assertEquals(0, PaginationUtils.clampPage(-100));
        assertEquals(5, PaginationUtils.clampPage(5));
    }

    @Test
    void testSecurityHeadersAndMdcCorrelationId() throws Exception {
        mockMvc.perform(get("/api/v1/auth/ping"))
                .andExpect(status().isOk())
                .andExpect(header().string("X-Frame-Options", "DENY"))
                .andExpect(header().string("X-Content-Type-Options", "nosniff"))
                .andExpect(header().exists("X-Correlation-ID"));
    }

    @Test
    void testActuator_PublicHealthAndProtectedMetrics() throws Exception {
        // /actuator/health is publicly accessible
        mockMvc.perform(get("/actuator/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").exists());

        // /actuator/metrics is protected (requires ADMIN role)
        mockMvc.perform(get("/actuator/metrics"))
                .andExpect(status().isForbidden());
    }
}
