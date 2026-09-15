package com.homestock.modules.deals.repository;

import com.homestock.modules.deals.entity.ShopProductOffer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ShopProductOfferRepository extends JpaRepository<ShopProductOffer, UUID> {

    List<ShopProductOffer> findByShopId(UUID shopId);

    List<ShopProductOffer> findByShopIdIn(List<UUID> shopIds);

    List<ShopProductOffer> findByProductId(UUID productId);

    @Query("SELECT o FROM ShopProductOffer o WHERE o.shop.id IN :shopIds AND " +
           "(LOWER(o.normalizedName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(o.rawProductName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(o.brand) LIKE LOWER(CONCAT('%', :query, '%')))")
    List<ShopProductOffer> searchOffersInShops(
            @Param("shopIds") List<UUID> shopIds,
            @Param("query") String query
    );

    @Query("SELECT o FROM ShopProductOffer o WHERE o.shop.id = :shopId AND " +
           "LOWER(o.normalizedName) = LOWER(:normalizedName)")
    List<ShopProductOffer> findByShopIdAndNormalizedName(
            @Param("shopId") UUID shopId,
            @Param("normalizedName") String normalizedName
    );

    List<ShopProductOffer> findByShopIdOrderByRawProductNameAsc(UUID shopId);

    long countByShopId(UUID shopId);

    @Query("SELECT o FROM ShopProductOffer o WHERE o.shop.id = :shopId AND " +
           "o.availabilityStatus = :status")
    List<ShopProductOffer> findByShopIdAndAvailabilityStatus(
            @Param("shopId") UUID shopId,
            @Param("status") String status
    );
}
