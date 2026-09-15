package com.homestock.modules.shop.service;

import com.homestock.core.exception.BusinessRuleException;
import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.core.security.ShopSecurityService;
import com.homestock.modules.deals.entity.NearbyShop;
import com.homestock.modules.deals.repository.NearbyShopRepository;
import com.homestock.modules.deals.repository.ShopProductOfferRepository;
import com.homestock.modules.shop.dto.ShopSubscriptionResponse;
import com.homestock.modules.shop.dto.SubscriptionPlanResponse;
import com.homestock.modules.shop.entity.ShopSubscription;
import com.homestock.modules.shop.entity.SubscriptionPlan;
import com.homestock.modules.shop.repository.ShopSubscriptionRepository;
import com.homestock.modules.shop.repository.SubscriptionPlanRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ShopSubscriptionService {

    private static final Logger log = LoggerFactory.getLogger(ShopSubscriptionService.class);

    private final ShopSubscriptionRepository subscriptionRepository;
    private final SubscriptionPlanRepository planRepository;
    private final NearbyShopRepository nearbyShopRepository;
    private final ShopProductOfferRepository shopProductOfferRepository;
    private final ShopSecurityService shopSecurityService;

    /**
     * Get all active subscription tiers available for shops.
     */
    public List<SubscriptionPlanResponse> getAllPlans() {
        return planRepository.findByIsActiveTrueOrderBySortOrderAsc().stream()
                .map(SubscriptionPlanResponse::fromEntity)
                .toList();
    }

    /**
     * Get active subscription for a shop.
     */
    public ShopSubscriptionResponse getShopSubscription(UUID shopId) {
        validateOwnerOrAdmin(shopId);

        NearbyShop shop = nearbyShopRepository.findById(shopId)
                .orElseThrow(() -> new ResourceNotFoundException("Shop not found"));

        long count = shopProductOfferRepository.countByShopId(shopId);

        ShopSubscription sub = subscriptionRepository.findActiveSubscription(shopId)
                .orElseGet(() -> {
                    // Fallback create FREE if missing
                    SubscriptionPlan free = planRepository.findByName("FREE")
                            .orElse(null);
                    if (free != null) {
                        ShopSubscription defaultSub = ShopSubscription.builder()
                                .shop(shop)
                                .plan(free)
                                .status("ACTIVE")
                                .startedAt(Instant.now())
                                .build();
                        return subscriptionRepository.save(defaultSub);
                    }
                    return null;
                });

        return ShopSubscriptionResponse.fromEntity(sub, count);
    }

    /**
     * Upgrade / switch subscription plan for a shop.
     * Note: In MVP, payment is simulated/instant activation.
     */
    @Transactional
    public ShopSubscriptionResponse upgradePlan(UUID shopId, String planName) {
        validateOwnerOrAdmin(shopId);

        NearbyShop shop = nearbyShopRepository.findById(shopId)
                .orElseThrow(() -> new ResourceNotFoundException("Shop not found"));

        SubscriptionPlan targetPlan = planRepository.findByName(planName.toUpperCase().trim())
                .orElseThrow(() -> new ResourceNotFoundException("Subscription plan not found: " + planName));

        // Mark existing active subscriptions as CANCELLED/SUPERSEDED
        subscriptionRepository.findActiveSubscription(shopId).ifPresent(oldSub -> {
            oldSub.setStatus("SUPERSEDED");
            oldSub.setCancelledAt(Instant.now());
            subscriptionRepository.save(oldSub);
        });

        // Create new active subscription (30 days validity for paid, indefinite for free)
        Instant expiresAt = "FREE".equalsIgnoreCase(targetPlan.getName()) ? null : Instant.now().plus(30, ChronoUnit.DAYS);

        ShopSubscription newSub = ShopSubscription.builder()
                .shop(shop)
                .plan(targetPlan)
                .status("ACTIVE")
                .startedAt(Instant.now())
                .expiresAt(expiresAt)
                .paymentProvider("HOMESTOCK_IN_APP")
                .paymentReference("SUB-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                .build();

        ShopSubscription saved = subscriptionRepository.save(newSub);
        log.info("Shop subscription updated: shopId={}, plan={}", shopId, targetPlan.getName());

        long count = shopProductOfferRepository.countByShopId(shopId);
        return ShopSubscriptionResponse.fromEntity(saved, count);
    }

    private void validateOwnerOrAdmin(UUID shopId) {
        if (!shopSecurityService.canManageShop(shopId)) {
            throw new BusinessRuleException("FORBIDDEN", "Not authorized to manage this shop's subscription");
        }
    }
}
