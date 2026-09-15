package com.homestock.modules.shop.repository;

import com.homestock.modules.shop.entity.ShopSubscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface ShopSubscriptionRepository extends JpaRepository<ShopSubscription, UUID> {

    @Query("SELECT s FROM ShopSubscription s WHERE s.shop.id = :shopId AND s.status IN ('ACTIVE', 'TRIAL')")
    Optional<ShopSubscription> findActiveSubscription(@Param("shopId") UUID shopId);

    Optional<ShopSubscription> findFirstByShopIdOrderByCreatedAtDesc(UUID shopId);
}
