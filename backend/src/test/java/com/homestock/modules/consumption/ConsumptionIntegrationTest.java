package com.homestock.modules.consumption;

import com.homestock.core.security.UserPrincipal;
import com.homestock.modules.auth.dto.RegisterRequest;
import com.homestock.modules.auth.service.AuthService;
import com.homestock.modules.consumption.dto.*;
import com.homestock.modules.consumption.entity.QuantityStatus;
import com.homestock.modules.consumption.service.ConsumptionService;
import com.homestock.modules.home.dto.CreateHomeRequest;
import com.homestock.modules.home.dto.HomeDto;
import com.homestock.modules.home.service.HomeService;
import com.homestock.modules.inventory.dto.CreateInventoryItemRequest;
import com.homestock.modules.inventory.dto.InventoryItemDto;
import com.homestock.modules.inventory.service.InventoryService;
import com.homestock.modules.purchase.dto.CreatePurchaseItemRequest;
import com.homestock.modules.purchase.dto.CreatePurchaseRequest;
import com.homestock.modules.purchase.service.PurchaseService;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("local")
@Transactional
class ConsumptionIntegrationTest {

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private HomeService homeService;

    @Autowired
    private InventoryService inventoryService;

    @Autowired
    private PurchaseService purchaseService;

    @Autowired
    private ConsumptionService consumptionService;

    private User testUser;
    private HomeDto testHome;
    private InventoryItemDto riceItem;

    @BeforeEach
    void setUp() {
        String email = "consumer_" + UUID.randomUUID().toString().substring(0, 8) + "@example.com";
        RegisterRequest reg = new RegisterRequest();
        reg.setEmail(email);
        reg.setPassword("Password@123");
        reg.setFullName("Gowtham Family");
        authService.register(reg);

        testUser = userRepository.findByEmail(email).orElseThrow();
        UserPrincipal principal = UserPrincipal.create(testUser);
        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);

        CreateHomeRequest homeReq = new CreateHomeRequest();
        homeReq.setName("Smart Household");
        testHome = homeService.createHome(homeReq);

        CreateInventoryItemRequest itemReq = new CreateInventoryItemRequest();
        itemReq.setName("Basmati Rice");
        itemReq.setUnit("kg");
        itemReq.setQuantity(new BigDecimal("5.0"));
        itemReq.setMinimumQuantity(new BigDecimal("1.0"));
        riceItem = inventoryService.createItem(testHome.getId(), itemReq);
    }

    @Test
    @DisplayName("End-to-End: Purchase history triggers consumption calculation and generates What-Do-I-Need recommendations")
    void testPurchaseHistoryAndSmartRecommendations() {
        // Log consecutive purchases across days to establish a 7-day cycle
        LocalDate date1 = LocalDate.now().minusDays(14);
        CreatePurchaseItemRequest pItem1 = new CreatePurchaseItemRequest();
        pItem1.setInventoryItemId(riceItem.getId());
        pItem1.setItemName("Basmati Rice");
        pItem1.setQuantity(new BigDecimal("5.0"));
        pItem1.setUnit("kg");
        pItem1.setUnitPrice(new BigDecimal("60"));

        CreatePurchaseRequest purchase1 = new CreatePurchaseRequest();
        purchase1.setPurchaseDate(date1);
        purchase1.setTotalAmount(new BigDecimal("300"));
        purchase1.setItems(List.of(pItem1));
        purchaseService.recordPurchase(testHome.getId(), purchase1);

        LocalDate date2 = LocalDate.now().minusDays(7);
        CreatePurchaseItemRequest pItem2 = new CreatePurchaseItemRequest();
        pItem2.setInventoryItemId(riceItem.getId());
        pItem2.setItemName("Basmati Rice");
        pItem2.setQuantity(new BigDecimal("5.0"));
        pItem2.setUnit("kg");
        pItem2.setUnitPrice(new BigDecimal("60"));

        CreatePurchaseRequest purchase2 = new CreatePurchaseRequest();
        purchase2.setPurchaseDate(date2);
        purchase2.setTotalAmount(new BigDecimal("300"));
        purchase2.setItems(List.of(pItem2));
        purchaseService.recordPurchase(testHome.getId(), purchase2);

        // Verify consumption profile was generated
        ConsumptionProfileDto profile = consumptionService.getConsumptionProfile(testHome.getId(), riceItem.getId());
        assertThat(profile).isNotNull();
        assertThat(profile.getAveragePurchaseInterval()).isEqualByComparingTo(new BigDecimal("7.00"));
        assertThat(profile.getWeightedDailyConsumption()).isGreaterThan(BigDecimal.ZERO);

        // Fast qualitative status confirmation: user marks "About Half" in 2 taps
        ConfirmStatusRequest confirmReq = new ConfirmStatusRequest();
        confirmReq.setStatus(QuantityStatus.ABOUT_HALF);
        PredictionDto updatedPrediction = consumptionService.confirmStatus(riceItem.getId(), confirmReq);

        assertThat(updatedPrediction).isNotNull();
        assertThat(updatedPrediction.getQuantityStatus()).isEqualTo(QuantityStatus.ABOUT_HALF);

        // Verify "What Do I Need?" recommendations
        var recs = consumptionService.getSmartRecommendations(testHome.getId());
        assertThat(recs).isNotNull();

        // Verify Home Memory Insights
        HomeMemoryInsightDto insights = consumptionService.getHomeMemoryInsights(testHome.getId());
        assertThat(insights).isNotNull();
        assertThat(insights.getPrimaryInsight()).isNotEmpty();
    }
}
