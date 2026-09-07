package com.homestock.modules.smartshopping.repository;

import com.homestock.modules.smartshopping.entity.ProductOfferEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProductOfferRepository extends JpaRepository<ProductOfferEntity, UUID> {

    /**
     * Find cached offers for a specific provider and product.
     */
    Optional<ProductOfferEntity> findByProviderAndProviderProductId(String provider, String providerProductId);

    /**
     * Find all offers for a canonical product ID (cross-provider matching).
     */
    List<ProductOfferEntity> findByCanonicalProductId(String canonicalProductId);

    /**
     * Find fresh cached offers (checked within TTL window).
     */
    @Query("SELECT po FROM ProductOfferEntity po WHERE po.canonicalProductId = :canonicalId AND po.lastCheckedAt >= :cutoff")
    List<ProductOfferEntity> findFreshOffers(String canonicalId, Instant cutoff);

    /**
     * Find offers by product name similarity for a given provider.
     */
    @Query("SELECT po FROM ProductOfferEntity po WHERE po.provider = :provider AND LOWER(po.productName) LIKE LOWER(CONCAT('%', :query, '%')) AND po.lastCheckedAt >= :cutoff")
    List<ProductOfferEntity> searchByName(String provider, String query, Instant cutoff);

    /**
     * Delete stale offers older than the given timestamp.
     */
    void deleteByLastCheckedAtBefore(Instant cutoff);
}
