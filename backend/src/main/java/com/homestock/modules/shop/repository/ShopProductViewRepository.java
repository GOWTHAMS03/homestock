package com.homestock.modules.shop.repository;

import com.homestock.modules.shop.entity.ShopProductView;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public interface ShopProductViewRepository extends JpaRepository<ShopProductView, UUID> {

    long countByShopIdAndViewedAtAfter(UUID shopId, Instant since);

    @Query("SELECT v.shopProduct.id, COUNT(v) as cnt FROM ShopProductView v " +
           "WHERE v.shop.id = :shopId AND v.viewedAt >= :since AND v.shopProduct IS NOT NULL " +
           "GROUP BY v.shopProduct.id ORDER BY cnt DESC")
    List<Object[]> findTopViewedProducts(@Param("shopId") UUID shopId, @Param("since") Instant since);
}
