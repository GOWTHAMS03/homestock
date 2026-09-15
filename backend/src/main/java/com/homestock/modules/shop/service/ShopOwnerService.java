package com.homestock.modules.shop.service;

import com.homestock.core.exception.BusinessRuleException;
import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.core.security.AppRole;
import com.homestock.core.security.ShopSecurityService;
import com.homestock.modules.deals.entity.NearbyShop;
import com.homestock.modules.deals.entity.ShopProductOffer;
import com.homestock.modules.deals.repository.NearbyShopRepository;
import com.homestock.modules.deals.repository.ShopProductOfferRepository;
import com.homestock.modules.product.entity.Product;
import com.homestock.modules.product.repository.ProductRepository;
import com.homestock.modules.shop.dto.*;
import com.homestock.modules.shop.entity.*;
import com.homestock.modules.shop.repository.*;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;

@Service
@RequiredArgsConstructor
public class ShopOwnerService {

    private static final Logger log = LoggerFactory.getLogger(ShopOwnerService.class);

    private final NearbyShopRepository nearbyShopRepository;
    private final ShopProductOfferRepository shopProductOfferRepository;
    private final ProductRepository productRepository;
    private final ShopProductPriceHistoryRepository priceHistoryRepository;
    private final ShopDealRepository shopDealRepository;
    private final ShopSubscriptionRepository subscriptionRepository;
    private final SubscriptionPlanRepository planRepository;
    private final UserRepository userRepository;
    private final ShopSecurityService shopSecurityService;

    // ═══════════════════════════════════════════
    // Shop Registration & Profile
    // ═══════════════════════════════════════════

    @Transactional
    public ShopProfileResponse registerShop(ShopRegistrationRequest request) {
        UUID userId = shopSecurityService.getAuthenticatedUserId();
        if (userId == null) {
            throw new BusinessRuleException("UNAUTHORIZED", "Authentication required");
        }

        // Upgrade user to SHOP_OWNER role
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (user.getAppRole() == AppRole.USER) {
            user.setAppRole(AppRole.SHOP_OWNER);
            userRepository.save(user);
        }

        // Validate coordinates
        validateCoordinates(request.getLatitude(), request.getLongitude());

        // Create the shop
        NearbyShop shop = NearbyShop.builder()
                .name(request.getShopName().trim())
                .normalizedName(request.getShopName().trim().toLowerCase())
                .ownerName(request.getOwnerName().trim())
                .ownerId(userId)
                .verificationStatus("PENDING")
                .shopType(request.getShopType() != null ? request.getShopType() : "GROCERY")
                .address(request.getAddress())
                .area(request.getArea())
                .city(request.getCity() != null ? request.getCity() : "Local")
                .state(request.getState())
                .postalCode(request.getPostalCode())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .phone(request.getPhone())
                .email(request.getEmail())
                .whatsappNumber(request.getWhatsappNumber())
                .openingTime(request.getOpeningTime())
                .closingTime(request.getClosingTime())
                .shopImageUrl(request.getShopImageUrl())
                .gstNumber(request.getGstNumber())
                .category(request.getShopCategory())
                .source("OWNER")
                .confidenceScore(50)
                .isOpen(true)
                .isVerified(false)
                .active(true)
                .build();

        NearbyShop saved = nearbyShopRepository.save(shop);

        // Auto-assign FREE subscription plan
        assignFreePlan(saved);

        log.info("Shop registered: id={}, name='{}', owner={}", saved.getId(), saved.getName(), userId);

        return ShopProfileResponse.fromEntity(saved);
    }

    @Transactional
    public ShopProfileResponse updateShopProfile(UUID shopId, ShopRegistrationRequest request) {
        NearbyShop shop = getShopForOwner(shopId);

        if (request.getShopName() != null) {
            shop.setName(request.getShopName().trim());
            shop.setNormalizedName(request.getShopName().trim().toLowerCase());
        }
        if (request.getOwnerName() != null) shop.setOwnerName(request.getOwnerName().trim());
        if (request.getPhone() != null) shop.setPhone(request.getPhone());
        if (request.getEmail() != null) shop.setEmail(request.getEmail());
        if (request.getAddress() != null) shop.setAddress(request.getAddress());
        if (request.getArea() != null) shop.setArea(request.getArea());
        if (request.getCity() != null) shop.setCity(request.getCity());
        if (request.getState() != null) shop.setState(request.getState());
        if (request.getPostalCode() != null) shop.setPostalCode(request.getPostalCode());
        if (request.getOpeningTime() != null) shop.setOpeningTime(request.getOpeningTime());
        if (request.getClosingTime() != null) shop.setClosingTime(request.getClosingTime());
        if (request.getShopType() != null) shop.setShopType(request.getShopType());
        if (request.getShopImageUrl() != null) shop.setShopImageUrl(request.getShopImageUrl());
        if (request.getGstNumber() != null) shop.setGstNumber(request.getGstNumber());
        if (request.getWhatsappNumber() != null) shop.setWhatsappNumber(request.getWhatsappNumber());

        if (request.getLatitude() != null && request.getLongitude() != null) {
            validateCoordinates(request.getLatitude(), request.getLongitude());
            shop.setLatitude(request.getLatitude());
            shop.setLongitude(request.getLongitude());
        }

        NearbyShop saved = nearbyShopRepository.save(shop);
        return ShopProfileResponse.fromEntity(saved);
    }

    public ShopProfileResponse getMyShop() {
        UUID userId = shopSecurityService.getAuthenticatedUserId();
        NearbyShop shop = nearbyShopRepository.findByOwnerId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("No shop found for this user"));

        ShopProfileResponse response = ShopProfileResponse.fromEntity(shop);
        enrichWithSubscription(response, shop.getId());
        return response;
    }

    public ShopProfileResponse getShopProfile(UUID shopId) {
        NearbyShop shop = nearbyShopRepository.findById(shopId)
                .orElseThrow(() -> new ResourceNotFoundException("Shop not found"));

        ShopProfileResponse response = ShopProfileResponse.fromEntity(shop);
        enrichWithSubscription(response, shop.getId());
        return response;
    }

    // ═══════════════════════════════════════════
    // Product Catalog Management
    // ═══════════════════════════════════════════

    @Transactional
    public ShopProductResponse addProduct(UUID shopId, ShopProductRequest request) {
        NearbyShop shop = getShopForOwner(shopId);
        enforceProductLimit(shopId);

        // Link to global product if barcode/productId provided
        Product globalProduct = null;
        if (request.getProductId() != null) {
            globalProduct = productRepository.findById(request.getProductId()).orElse(null);
        } else if (request.getBarcode() != null && !request.getBarcode().isBlank()) {
            globalProduct = productRepository.findByBarcode(request.getBarcode()).orElse(null);
        }

        BigDecimal effectivePrice = request.getPrice();
        if (request.getOfferPrice() != null && request.getOfferStart() != null && request.getOfferEnd() != null) {
            Instant now = Instant.now();
            if (!now.isBefore(request.getOfferStart()) && !now.isAfter(request.getOfferEnd())) {
                effectivePrice = request.getOfferPrice();
            }
        }

        ShopProductOffer offer = ShopProductOffer.builder()
                .shop(shop)
                .product(globalProduct)
                .rawProductName(request.getProductName().trim())
                .normalizedName(request.getProductName().trim().toLowerCase())
                .brand(request.getBrand())
                .packageSize(request.getPackageSize())
                .unit(request.getUnit() != null ? request.getUnit() : "pcs")
                .price(request.getPrice())
                .mrp(request.getMrp())
                .effectivePrice(effectivePrice)
                .offerPrice(request.getOfferPrice())
                .offerStart(request.getOfferStart())
                .offerEnd(request.getOfferEnd())
                .availabilityStatus(request.getAvailabilityStatus() != null ? request.getAvailabilityStatus() : "AVAILABLE")
                .stockQuantity(request.getStockQuantity())
                .stockVisibility(request.getStockVisibility() != null ? request.getStockVisibility() : "STATUS_ONLY")
                .stockStatus("AVAILABLE".equals(request.getAvailabilityStatus()) ? "IN_STOCK" :
                             "LIMITED".equals(request.getAvailabilityStatus()) ? "LOW_STOCK" : "OUT_OF_STOCK")
                .source("SHOP_CATALOG")
                .confidence("HIGH")
                .lastVerifiedAt(Instant.now())
                .build();

        ShopProductOffer saved = shopProductOfferRepository.save(offer);

        // Update shop product count and inventory timestamp
        shop.setProductCount(shop.getProductCount() + 1);
        shop.setLastInventoryUpdate(Instant.now());
        nearbyShopRepository.save(shop);

        log.info("Product added to shop: shopId={}, product='{}'", shopId, saved.getRawProductName());

        ShopProductResponse response = ShopProductResponse.fromEntity(saved);
        response.setStockQuantity(saved.getStockQuantity()); // Owner can see quantity
        return response;
    }

    @Transactional
    public ShopProductResponse updateProduct(UUID shopId, UUID productId, ShopProductRequest request) {
        getShopForOwner(shopId); // Authorization check

        ShopProductOffer offer = shopProductOfferRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Product not found"));

        if (!offer.getShop().getId().equals(shopId)) {
            throw new BusinessRuleException("FORBIDDEN", "Product does not belong to this shop");
        }

        // Track price changes
        if (request.getPrice() != null && !request.getPrice().equals(offer.getPrice())) {
            ShopProductPriceHistory history = ShopProductPriceHistory.builder()
                    .shopProduct(offer)
                    .oldPrice(offer.getPrice())
                    .newPrice(request.getPrice())
                    .oldOfferPrice(offer.getOfferPrice())
                    .newOfferPrice(request.getOfferPrice())
                    .changedBy(shopSecurityService.getAuthenticatedUserId())
                    .build();
            priceHistoryRepository.save(history);
        }

        // Update fields
        if (request.getProductName() != null) {
            offer.setRawProductName(request.getProductName().trim());
            offer.setNormalizedName(request.getProductName().trim().toLowerCase());
        }
        if (request.getBrand() != null) offer.setBrand(request.getBrand());
        if (request.getPrice() != null) offer.setPrice(request.getPrice());
        if (request.getMrp() != null) offer.setMrp(request.getMrp());
        if (request.getOfferPrice() != null) offer.setOfferPrice(request.getOfferPrice());
        if (request.getOfferStart() != null) offer.setOfferStart(request.getOfferStart());
        if (request.getOfferEnd() != null) offer.setOfferEnd(request.getOfferEnd());
        if (request.getAvailabilityStatus() != null) {
            offer.setAvailabilityStatus(request.getAvailabilityStatus());
            offer.setStockStatus("AVAILABLE".equals(request.getAvailabilityStatus()) ? "IN_STOCK" :
                                 "LIMITED".equals(request.getAvailabilityStatus()) ? "LOW_STOCK" : "OUT_OF_STOCK");
        }
        if (request.getStockQuantity() != null) offer.setStockQuantity(request.getStockQuantity());
        if (request.getStockVisibility() != null) offer.setStockVisibility(request.getStockVisibility());

        // Recalculate effective price
        offer.setEffectivePrice(offer.getCurrentEffectivePrice());
        offer.setLastVerifiedAt(Instant.now());

        ShopProductOffer saved = shopProductOfferRepository.save(offer);

        // Update shop inventory timestamp
        NearbyShop shop = saved.getShop();
        shop.setLastInventoryUpdate(Instant.now());
        nearbyShopRepository.save(shop);

        ShopProductResponse response = ShopProductResponse.fromEntity(saved);
        response.setStockQuantity(saved.getStockQuantity());
        return response;
    }

    @Transactional
    public void deleteProduct(UUID shopId, UUID productId) {
        NearbyShop shop = getShopForOwner(shopId);

        ShopProductOffer offer = shopProductOfferRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Product not found"));

        if (!offer.getShop().getId().equals(shopId)) {
            throw new BusinessRuleException("FORBIDDEN", "Product does not belong to this shop");
        }

        shopProductOfferRepository.delete(offer);

        shop.setProductCount(Math.max(0, shop.getProductCount() - 1));
        shop.setLastInventoryUpdate(Instant.now());
        nearbyShopRepository.save(shop);

        log.info("Product deleted from shop: shopId={}, productId={}", shopId, productId);
    }

    public List<ShopProductResponse> getShopProducts(UUID shopId) {
        List<ShopProductOffer> offers = shopProductOfferRepository.findByShopIdOrderByRawProductNameAsc(shopId);
        boolean isOwner = shopSecurityService.isShopOwner(shopId);

        return offers.stream().map(offer -> {
            ShopProductResponse response = ShopProductResponse.fromEntity(offer);
            if (isOwner) {
                response.setStockQuantity(offer.getStockQuantity());
            }
            return response;
        }).toList();
    }

    // ═══════════════════════════════════════════
    // Deals Management
    // ═══════════════════════════════════════════

    @Transactional
    public ShopDealResponse createDeal(UUID shopId, ShopDealRequest request) {
        NearbyShop shop = getShopForOwner(shopId);

        if (request.getEndDate().isBefore(request.getStartDate())) {
            throw new BusinessRuleException("INVALID_DATES", "End date must be after start date");
        }

        ShopProductOffer product = null;
        if (request.getShopProductId() != null) {
            product = shopProductOfferRepository.findById(request.getShopProductId()).orElse(null);
        }

        ShopDeal deal = ShopDeal.builder()
                .shop(shop)
                .shopProduct(product)
                .title(request.getTitle().trim())
                .description(request.getDescription())
                .dealType(request.getDealType() != null ? request.getDealType() : "DISCOUNT")
                .originalPrice(request.getOriginalPrice())
                .offerPrice(request.getOfferPrice())
                .discountPercent(request.getDiscountPercent())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .isActive(true)
                .build();

        ShopDeal saved = shopDealRepository.save(deal);
        log.info("Deal created: shopId={}, dealId={}, title='{}'", shopId, saved.getId(), saved.getTitle());
        return ShopDealResponse.fromEntity(saved);
    }

    @Transactional
    public ShopDealResponse updateDeal(UUID shopId, UUID dealId, ShopDealRequest request) {
        getShopForOwner(shopId);

        ShopDeal deal = shopDealRepository.findById(dealId)
                .orElseThrow(() -> new ResourceNotFoundException("Deal not found"));

        if (!deal.getShop().getId().equals(shopId)) {
            throw new BusinessRuleException("FORBIDDEN", "Deal does not belong to this shop");
        }

        if (request.getTitle() != null) deal.setTitle(request.getTitle().trim());
        if (request.getDescription() != null) deal.setDescription(request.getDescription());
        if (request.getDealType() != null) deal.setDealType(request.getDealType());
        if (request.getOriginalPrice() != null) deal.setOriginalPrice(request.getOriginalPrice());
        if (request.getOfferPrice() != null) deal.setOfferPrice(request.getOfferPrice());
        if (request.getDiscountPercent() != null) deal.setDiscountPercent(request.getDiscountPercent());
        if (request.getStartDate() != null) deal.setStartDate(request.getStartDate());
        if (request.getEndDate() != null) deal.setEndDate(request.getEndDate());

        return ShopDealResponse.fromEntity(shopDealRepository.save(deal));
    }

    @Transactional
    public void deleteDeal(UUID shopId, UUID dealId) {
        getShopForOwner(shopId);
        ShopDeal deal = shopDealRepository.findById(dealId)
                .orElseThrow(() -> new ResourceNotFoundException("Deal not found"));
        if (!deal.getShop().getId().equals(shopId)) {
            throw new BusinessRuleException("FORBIDDEN", "Deal does not belong to this shop");
        }
        deal.setIsActive(false);
        shopDealRepository.save(deal);
    }

    public List<ShopDealResponse> getShopDeals(UUID shopId) {
        return shopDealRepository.findByShopIdOrderByCreatedAtDesc(shopId).stream()
                .map(ShopDealResponse::fromEntity)
                .toList();
    }

    public List<ShopDealResponse> getActiveDeals(UUID shopId) {
        return shopDealRepository.findActiveDeals(shopId, Instant.now()).stream()
                .map(ShopDealResponse::fromEntity)
                .toList();
    }

    // ═══════════════════════════════════════════
    // Admin Verification
    // ═══════════════════════════════════════════

    @Transactional
    public ShopProfileResponse verifyShop(UUID shopId) {
        NearbyShop shop = nearbyShopRepository.findById(shopId)
                .orElseThrow(() -> new ResourceNotFoundException("Shop not found"));

        shop.setVerificationStatus("VERIFIED");
        shop.setIsVerified(true);
        shop.setConfidenceScore(Math.min(100, shop.getConfidenceScore() + 30));
        shop.setLastVerifiedAt(Instant.now());

        log.info("Shop verified by admin: shopId={}, name='{}'", shopId, shop.getName());
        return ShopProfileResponse.fromEntity(nearbyShopRepository.save(shop));
    }

    @Transactional
    public ShopProfileResponse rejectShop(UUID shopId, String reason) {
        NearbyShop shop = nearbyShopRepository.findById(shopId)
                .orElseThrow(() -> new ResourceNotFoundException("Shop not found"));

        shop.setVerificationStatus("REJECTED");
        shop.setIsVerified(false);
        if (reason != null) shop.setNotes(reason);

        log.info("Shop rejected by admin: shopId={}, reason='{}'", shopId, reason);
        return ShopProfileResponse.fromEntity(nearbyShopRepository.save(shop));
    }

    @Transactional
    public ShopProfileResponse suspendShop(UUID shopId, String reason) {
        NearbyShop shop = nearbyShopRepository.findById(shopId)
                .orElseThrow(() -> new ResourceNotFoundException("Shop not found"));

        shop.setVerificationStatus("SUSPENDED");
        shop.setActive(false);
        shop.setIsVerified(false);
        if (reason != null) shop.setNotes(reason);

        log.info("Shop suspended by admin: shopId={}, reason='{}'", shopId, reason);
        return ShopProfileResponse.fromEntity(nearbyShopRepository.save(shop));
    }

    public List<ShopProfileResponse> getShopsByStatus(String status) {
        return nearbyShopRepository.findByVerificationStatus(status).stream()
                .map(ShopProfileResponse::fromEntity)
                .toList();
    }

    // ═══════════════════════════════════════════
    // Helpers
    // ═══════════════════════════════════════════

    private NearbyShop getShopForOwner(UUID shopId) {
        NearbyShop shop = nearbyShopRepository.findById(shopId)
                .orElseThrow(() -> new ResourceNotFoundException("Shop not found"));

        UUID userId = shopSecurityService.getAuthenticatedUserId();
        if (!shop.getOwnerId().equals(userId) && !shopSecurityService.isAdmin()) {
            throw new BusinessRuleException("FORBIDDEN", "You do not own this shop");
        }
        return shop;
    }

    private void enforceProductLimit(UUID shopId) {
        Optional<ShopSubscription> subOpt = subscriptionRepository.findActiveSubscription(shopId);
        int maxProducts = 50; // FREE default
        if (subOpt.isPresent()) {
            maxProducts = subOpt.get().getPlan().getMaxProducts();
        }

        long currentCount = shopProductOfferRepository.countByShopId(shopId);
        if (currentCount >= maxProducts) {
            throw new BusinessRuleException("PRODUCT_LIMIT_REACHED",
                    "You've reached your plan's product limit of " + maxProducts + ". Upgrade to add more.");
        }
    }

    private void assignFreePlan(NearbyShop shop) {
        SubscriptionPlan freePlan = planRepository.findByName("FREE")
                .orElse(null);
        if (freePlan == null) return;

        ShopSubscription subscription = ShopSubscription.builder()
                .shop(shop)
                .plan(freePlan)
                .status("ACTIVE")
                .startedAt(Instant.now())
                .build();
        subscriptionRepository.save(subscription);
    }

    private void enrichWithSubscription(ShopProfileResponse response, UUID shopId) {
        subscriptionRepository.findActiveSubscription(shopId).ifPresent(sub -> {
            response.setSubscriptionPlan(sub.getPlan().getName());
            response.setSubscriptionStatus(sub.getStatus());
            response.setMaxProducts(sub.getPlan().getMaxProducts());
        });
    }

    private void validateCoordinates(BigDecimal lat, BigDecimal lon) {
        if (lat == null || lon == null) {
            throw new BusinessRuleException("INVALID_COORDINATES", "Latitude and longitude are required");
        }
        if (lat.doubleValue() < -90 || lat.doubleValue() > 90 ||
            lon.doubleValue() < -180 || lon.doubleValue() > 180) {
            throw new BusinessRuleException("INVALID_COORDINATES", "Invalid latitude or longitude values");
        }
    }
}
