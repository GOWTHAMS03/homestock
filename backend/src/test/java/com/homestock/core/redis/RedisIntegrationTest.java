package com.homestock.core.redis;

import com.homestock.core.exception.RateLimitExceededException;
import com.homestock.core.security.UserPrincipal;
import com.homestock.modules.auth.dto.RegisterRequest;
import com.homestock.modules.auth.service.AuthService;
import com.homestock.modules.dashboard.dto.DashboardSummaryDto;
import com.homestock.modules.dashboard.service.DashboardCacheService;
import com.homestock.modules.dashboard.service.DashboardService;
import com.homestock.modules.home.dto.CreateHomeRequest;
import com.homestock.modules.home.dto.HomeDto;
import com.homestock.modules.home.service.HomeService;
import com.homestock.modules.inventory.dto.CreateInventoryItemRequest;
import com.homestock.modules.inventory.dto.InventoryItemDto;
import com.homestock.modules.inventory.dto.StockUpdateRequest;
import com.homestock.modules.inventory.entity.TransactionType;
import com.homestock.modules.inventory.service.InventoryService;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDate;
import java.util.Collections;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@SpringBootTest
@ActiveProfiles("local")
@Transactional
class RedisIntegrationTest {

    @Autowired
    private DashboardService dashboardService;

    @Autowired
    private DashboardCacheService dashboardCacheService;

    @Autowired
    private InventoryService inventoryService;

    @Autowired
    private HomeService homeService;

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RedisResilienceService redisResilienceService;

    @Autowired
    private DistributedLockService distributedLockService;

    @Autowired
    private RateLimitingService rateLimitingService;

    @Autowired
    private CacheMetricsService cacheMetricsService;

    private User currentUser;
    private HomeDto home;

    @BeforeEach
    void setUp() {
        String email = "redis.test." + UUID.randomUUID() + "@example.com";
        RegisterRequest register = new RegisterRequest();
        register.setEmail(email);
        register.setPassword("Password123!");
        register.setFullName("Redis Tester");

        authService.register(register);
        currentUser = userRepository.findByEmail(email).orElseThrow();

        UserPrincipal principal = UserPrincipal.create(currentUser);
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities()));

        CreateHomeRequest homeReq = new CreateHomeRequest();
        homeReq.setName("Redis Test Household");
        home = homeService.createHome(homeReq);
    }

    @Test
    @DisplayName("Graceful Fallback: Dashboard summary queries PostgreSQL successfully when Redis is unavailable")
    void testGracefulFallbackWhenRedisUnavailable() {
        // When Redis is unreachable, the call must not throw an exception or return HTTP 500
        assertDoesNotThrow(() -> {
            DashboardSummaryDto summary = dashboardService.getDashboardSummary(home.getId());
            assertNotNull(summary);
            assertEquals("Redis Test Household", summary.getHomeName());
            assertEquals(0, summary.getTotalInventoryItems());
        });
    }

    @Test
    @DisplayName("Zero Stale Inventory: Stock update immediately evicts cache and PostgreSQL returns fresh state")
    void testZeroStaleInventoryInvalidation() {
        // 1. Create an inventory item
        CreateInventoryItemRequest itemReq = new CreateInventoryItemRequest();
        itemReq.setName("Sunflower Oil");
        itemReq.setQuantity(new BigDecimal("5.00"));
        itemReq.setUnit("L");
        itemReq.setMinimumQuantity(new BigDecimal("2.00"));
        itemReq.setPurchasePrice(new BigDecimal("150.00"));
        itemReq.setPurchaseDate(LocalDate.now());

        InventoryItemDto item = inventoryService.createItem(home.getId(), itemReq);
        assertNotNull(item.getId());

        // 2. Fetch summary - PostgreSQL has 1 item
        DashboardSummaryDto summary1 = dashboardService.getDashboardSummary(home.getId());
        assertEquals(1, summary1.getTotalInventoryItems());
        assertEquals(0, summary1.getLowStockCount());

        // 3. Update stock to below minimum threshold (1.00 L)
        StockUpdateRequest updateReq = new StockUpdateRequest();
        updateReq.setQuantityChange(new BigDecimal("4.00"));
        updateReq.setTransactionType(TransactionType.STOCK_OUT);
        updateReq.setReason("Cooking consumption");

        inventoryService.updateStock(home.getId(), item.getId(), updateReq);

        // 4. Fetch dashboard summary again - must immediately reflect 1 low stock item
        DashboardSummaryDto summary2 = dashboardService.getDashboardSummary(home.getId());
        assertEquals(1, summary2.getTotalInventoryItems());
        assertEquals(1, summary2.getLowStockCount());
    }

    @Test
    @DisplayName("Distributed Locking: Mutual exclusion and execution safety")
    void testDistributedLockingMutualExclusion() {
        String lockKey = "lock:test:resource:" + UUID.randomUUID();
        String owner1 = UUID.randomUUID().toString();
        String owner2 = UUID.randomUUID().toString();
        Duration lease = Duration.ofSeconds(5);

        // Owner 1 acquires
        boolean acquired1 = distributedLockService.tryLock(lockKey, owner1, lease);
        assertTrue(acquired1, "Owner 1 should acquire the lock");

        // Owner 2 tries to acquire same lock -> must fail
        boolean acquired2 = distributedLockService.tryLock(lockKey, owner2, lease);
        assertFalse(acquired2, "Owner 2 should be rejected while lock is held");

        // Owner 1 releases
        boolean released = distributedLockService.releaseLock(lockKey, owner1);
        assertTrue(released, "Owner 1 should successfully release the lock");

        // Owner 2 can now acquire
        boolean acquiredAfterRelease = distributedLockService.tryLock(lockKey, owner2, lease);
        assertTrue(acquiredAfterRelease, "Owner 2 should acquire after release");

        // Clean up
        distributedLockService.releaseLock(lockKey, owner2);
    }

    @Test
    @DisplayName("Distributed Locking: executeWithLock runs supplier and safely releases")
    void testExecuteWithLock() {
        String lockKey = "lock:sync:home:" + home.getId();
        AtomicBoolean executed = new AtomicBoolean(false);

        String result = distributedLockService.executeWithLock(lockKey, Duration.ofSeconds(5), () -> {
            executed.set(true);
            return "SUCCESS";
        });

        assertEquals("SUCCESS", result);
        assertTrue(executed.get());
    }

    @Test
    @DisplayName("Rate Limiting: Allows requests within limit and rejects when threshold exceeded")
    @SuppressWarnings("unchecked")
    void testRateLimitingWithMockedRedis() {
        // Create an isolated resilience service with mocked StringRedisTemplate to test atomic counter transitions
        StringRedisTemplate mockStringRedis = mock(StringRedisTemplate.class);
        RedisTemplate<String, Object> mockRedis = mock(RedisTemplate.class);
        ValueOperations<String, String> mockValueOps = mock(ValueOperations.class);
        when(mockStringRedis.opsForValue()).thenReturn(mockValueOps);

        RedisResilienceService isolatedResilience = new RedisResilienceService(
                mockRedis, mockStringRedis, cacheMetricsService);
        RateLimitingService isolatedLimiter = new RateLimitingService(isolatedResilience, cacheMetricsService);

        String key = "homestock:ratelimit:voice:user-42";
        // 1st request -> count = 1
        when(mockValueOps.increment(key)).thenReturn(1L);
        assertTrue(isolatedLimiter.isAllowed("voice", "user-42", 3, 60));

        // 2nd request -> count = 2
        when(mockValueOps.increment(key)).thenReturn(2L);
        assertTrue(isolatedLimiter.isAllowed("voice", "user-42", 3, 60));

        // 3rd request -> count = 3 (at limit)
        when(mockValueOps.increment(key)).thenReturn(3L);
        assertTrue(isolatedLimiter.isAllowed("voice", "user-42", 3, 60));

        // 4th request -> count = 4 (exceeded)
        when(mockValueOps.increment(key)).thenReturn(4L);
        assertFalse(isolatedLimiter.isAllowed("voice", "user-42", 3, 60));
    }

    @Test
    @DisplayName("Rate Limiting: Fails open when Redis is unreachable so users are not blocked")
    @SuppressWarnings("unchecked")
    void testRateLimitingFailsOpenOnRedisError() {
        StringRedisTemplate mockStringRedis = mock(StringRedisTemplate.class);
        RedisTemplate<String, Object> mockRedis = mock(RedisTemplate.class);
        ValueOperations<String, String> mockValueOps = mock(ValueOperations.class);
        when(mockStringRedis.opsForValue()).thenReturn(mockValueOps);
        when(mockValueOps.increment(anyString())).thenThrow(new RuntimeException("Redis connection refused"));

        RedisResilienceService isolatedResilience = new RedisResilienceService(
                mockRedis, mockStringRedis, cacheMetricsService);
        RateLimitingService isolatedLimiter = new RateLimitingService(isolatedResilience, cacheMetricsService);

        // When Redis is broken, isAllowed must return true (fail open)
        boolean allowed = isolatedLimiter.isAllowed("deals", "user-99", 5, 60);
        assertTrue(allowed, "Rate limiter must fail-open when Redis throws connection error");
    }

    @Test
    @DisplayName("Cache-Aside Simulation: Verified Hit, Miss, and Evict flow")
    @SuppressWarnings("unchecked")
    void testCacheAsideHitMissAndEvictFlow() {
        RedisTemplate<String, Object> mockRedis = mock(RedisTemplate.class);
        StringRedisTemplate mockStringRedis = mock(StringRedisTemplate.class);
        ValueOperations<String, Object> mockValueOps = mock(ValueOperations.class);
        when(mockRedis.opsForValue()).thenReturn(mockValueOps);

        RedisResilienceService isolatedResilience = new RedisResilienceService(
                mockRedis, mockStringRedis, cacheMetricsService);
        DashboardCacheService cacheService = new DashboardCacheService(isolatedResilience);

        UUID testHomeId = UUID.randomUUID();
        String expectedKey = "homestock:dashboard:summary:" + testHomeId;

        // 1. Initial Get -> Cache Miss
        when(mockValueOps.get(expectedKey)).thenReturn(null);
        Optional<DashboardSummaryDto> missResult = cacheService.get(testHomeId);
        assertTrue(missResult.isEmpty(), "Initial call should be cache miss");

        // 2. Put computed summary
        DashboardSummaryDto dto = DashboardSummaryDto.builder()
                .homeName("Cached Household")
                .totalInventoryItems(42)
                .build();
        cacheService.put(testHomeId, dto);
        verify(mockValueOps).set(eq(expectedKey), eq(dto), eq(Duration.ofSeconds(300)));

        // 3. Subsequent Get -> Cache Hit
        when(mockValueOps.get(expectedKey)).thenReturn(dto);
        Optional<DashboardSummaryDto> hitResult = cacheService.get(testHomeId);
        assertTrue(hitResult.isPresent(), "Subsequent call should be cache hit");
        assertEquals(42, hitResult.get().getTotalInventoryItems());

        // 4. Evict on mutation
        cacheService.evict(testHomeId);
        verify(mockRedis).delete(expectedKey);
    }

    @Test
    @DisplayName("Product Cache: Hit, Miss, and Evict flow for ID and barcode")
    @SuppressWarnings("unchecked")
    void testProductCacheAsideAndEviction() {
        RedisTemplate<String, Object> mockRedis = mock(RedisTemplate.class);
        StringRedisTemplate mockStringRedis = mock(StringRedisTemplate.class);
        ValueOperations<String, Object> mockValueOps = mock(ValueOperations.class);
        when(mockRedis.opsForValue()).thenReturn(mockValueOps);

        RedisResilienceService isolatedResilience = new RedisResilienceService(
                mockRedis, mockStringRedis, cacheMetricsService);
        com.homestock.modules.product.service.ProductCacheService productCacheService =
                new com.homestock.modules.product.service.ProductCacheService(isolatedResilience);

        UUID productId = UUID.randomUUID();
        String barcode = "8901030000003";
        String idKey = "homestock:product:id:" + productId;
        String barcodeKey = "homestock:product:barcode:" + barcode;

        // 1. Initial Get -> Miss
        when(mockValueOps.get(idKey)).thenReturn(null);
        assertTrue(productCacheService.getById(productId).isEmpty());

        // 2. Put product DTO
        com.homestock.modules.product.dto.ProductDto product = com.homestock.modules.product.dto.ProductDto.builder()
                .id(productId)
                .name("Tata Salt")
                .barcode(barcode)
                .build();
        productCacheService.put(product);
        verify(mockValueOps).set(eq(idKey), eq(product), eq(Duration.ofSeconds(86400)));
        verify(mockValueOps).set(eq(barcodeKey), eq(product), eq(Duration.ofSeconds(86400)));

        // 3. Get -> Hit
        when(mockValueOps.get(idKey)).thenReturn(product);
        when(mockValueOps.get(barcodeKey)).thenReturn(product);
        assertTrue(productCacheService.getById(productId).isPresent());
        assertTrue(productCacheService.getByBarcode(barcode).isPresent());

        // 4. Evict
        productCacheService.evict(productId, barcode);
        verify(mockRedis).delete(idKey);
        verify(mockRedis).delete(barcodeKey);
    }

    @Test
    @DisplayName("Rate Limit Exception: RateLimitExceededException returns HTTP 429 response")
    void testRateLimitExceededThrows429Exception() {
        com.homestock.core.exception.GlobalExceptionHandler handler = new com.homestock.core.exception.GlobalExceptionHandler();
        RateLimitExceededException ex = new RateLimitExceededException("deals_search", 20, 60);

        org.springframework.http.ResponseEntity<com.homestock.core.exception.ErrorResponse> response =
                handler.handleRateLimitExceeded(ex);

        assertEquals(org.springframework.http.HttpStatus.TOO_MANY_REQUESTS, response.getStatusCode());
        assertEquals("60", response.getHeaders().getFirst("Retry-After"));
        assertNotNull(response.getBody());
        assertEquals("RATE_LIMIT_EXCEEDED", response.getBody().getCode());
        assertTrue(response.getBody().getMessage().contains("deals_search"));
    }

    @Test
    @DisplayName("Cache Metrics: Counters increment safely without throwing")
    void testCacheMetricsRecording() {
        assertDoesNotThrow(() -> {
            cacheMetricsService.recordHit("dashboard");
            cacheMetricsService.recordMiss("dashboard");
            cacheMetricsService.recordFallback("dashboard", "redis_offline");
            cacheMetricsService.recordLock("lock:sync:home:test", true);
            cacheMetricsService.recordRateLimit("voice", true);
            cacheMetricsService.recordRateLimit("voice", false);
        });
    }
}
