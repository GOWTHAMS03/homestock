package com.homestock;

import com.homestock.modules.auth.dto.AuthResponse;
import com.homestock.modules.auth.dto.LoginRequest;
import com.homestock.modules.auth.dto.RegisterRequest;
import com.homestock.modules.auth.service.AuthService;
import com.homestock.modules.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("local")
@Transactional
class HomeStockApplicationTests {

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Test
    void testRegisterAndLoginFlow() {
        RegisterRequest register = new RegisterRequest();
        register.setEmail("testuser@example.com");
        register.setPassword("SecretPassword123!");
        register.setFullName("Test User");
        register.setPhoneNumber("9876543210");

        AuthResponse registerResponse = authService.register(register);
        assertNotNull(registerResponse.getAccessToken());
        assertNotNull(registerResponse.getRefreshToken());
        assertEquals("Test User", registerResponse.getUser().getFullName());
        assertTrue(userRepository.existsByEmail("testuser@example.com"));

        LoginRequest login = new LoginRequest();
        login.setEmail("testuser@example.com");
        login.setPassword("SecretPassword123!");

        AuthResponse loginResponse = authService.login(login);
        assertNotNull(loginResponse.getAccessToken());
        assertEquals("testuser@example.com", loginResponse.getUser().getEmail());
    }
}
