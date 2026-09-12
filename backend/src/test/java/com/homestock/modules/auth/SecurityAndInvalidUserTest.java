package com.homestock.modules.auth;

import com.homestock.core.security.JwtTokenProvider;
import com.homestock.core.security.UserPrincipal;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("local")
@Transactional
class SecurityAndInvalidUserTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    private User activeUser;

    @BeforeEach
    void setUp() {
        activeUser = new User();
        activeUser.setEmail("active.user@homestock.app");
        activeUser.setPasswordHash("$2a$10$abcdefghijklmnopqrstuvwxyz123456");
        activeUser.setFullName("Active Test User");
        activeUser.setUsername("activeuser");
        activeUser.setStatus("ACTIVE");
        activeUser = userRepository.save(activeUser);
    }

    @Test
    void testValidTokenAccessSucceeds() throws Exception {
        String token = jwtTokenProvider.generateAccessToken(UserPrincipal.create(activeUser));

        mockMvc.perform(get("/api/v1/users/me")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.email", is("active.user@homestock.app")));
    }

    @Test
    void testDeletedUserTokenReturns401UserNotFound() throws Exception {
        String token = jwtTokenProvider.generateAccessToken(UserPrincipal.create(activeUser));

        // Mark user as deleted in database
        activeUser.setStatus("DELETED");
        activeUser.setDeletedAt(Instant.now());
        userRepository.save(activeUser);

        mockMvc.perform(get("/api/v1/users/me")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code", is("USER_NOT_FOUND")))
                .andExpect(jsonPath("$.message", containsString("could not be verified")));
    }

    @Test
    void testNonExistentUserTokenReturns401UserNotFound() throws Exception {
        // Generate valid token for a user that does NOT exist in DB
        User phantomUser = new User();
        phantomUser.setId(UUID.randomUUID());
        phantomUser.setEmail("phantom@homestock.app");
        phantomUser.setFullName("Phantom User");
        String token = jwtTokenProvider.generateAccessToken(UserPrincipal.create(phantomUser));

        mockMvc.perform(get("/api/v1/users/me")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code", is("USER_NOT_FOUND")));
    }

    @Test
    void testDisabledUserTokenReturns401Or403AccountDisabled() throws Exception {
        String token = jwtTokenProvider.generateAccessToken(UserPrincipal.create(activeUser));

        // Mark user as disabled
        activeUser.setStatus("DISABLED");
        userRepository.save(activeUser);

        mockMvc.perform(get("/api/v1/users/me")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().is4xxClientError())
                .andExpect(jsonPath("$.code", is("ACCOUNT_DISABLED")));
    }

    @Test
    void testMissingTokenReturns401() throws Exception {
        mockMvc.perform(get("/api/v1/users/me")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnauthorized());
    }
}
