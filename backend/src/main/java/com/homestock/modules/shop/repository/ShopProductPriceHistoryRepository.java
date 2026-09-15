package com.homestock.modules.shop.repository;

import com.homestock.modules.shop.entity.ShopProductPriceHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ShopProductPriceHistoryRepository extends JpaRepository<ShopProductPriceHistory, UUID> {
    List<ShopProductPriceHistory> findByShopProductIdOrderByCreatedAtDesc(UUID shopProductId);
}
