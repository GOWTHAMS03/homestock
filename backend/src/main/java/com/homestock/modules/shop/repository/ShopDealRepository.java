package com.homestock.modules.shop.repository;

import com.homestock.modules.shop.entity.ShopDeal;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public interface ShopDealRepository extends JpaRepository<ShopDeal, UUID> {

    List<ShopDeal> findByShopIdOrderByCreatedAtDesc(UUID shopId);

    @Query("SELECT d FROM ShopDeal d WHERE d.shop.id = :shopId AND d.isActive = true " +
           "AND d.startDate <= :now AND d.endDate >= :now ORDER BY d.endDate ASC")
    List<ShopDeal> findActiveDeals(@Param("shopId") UUID shopId, @Param("now") Instant now);

    @Query("SELECT COUNT(d) FROM ShopDeal d WHERE d.shop.id = :shopId AND d.isActive = true " +
           "AND d.startDate <= :now AND d.endDate >= :now")
    long countActiveDeals(@Param("shopId") UUID shopId, @Param("now") Instant now);
}
