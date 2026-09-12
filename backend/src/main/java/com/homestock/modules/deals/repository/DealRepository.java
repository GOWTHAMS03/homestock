package com.homestock.modules.deals.repository;

import com.homestock.modules.deals.entity.DealEntity;
import com.homestock.modules.deals.model.DealSource;
import com.homestock.modules.deals.model.DealValidationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DealRepository extends JpaRepository<DealEntity, UUID> {

    Optional<DealEntity> findBySourceAndExternalProductId(DealSource source, String externalProductId);

    List<DealEntity> findByProductId(UUID productId);

    List<DealEntity> findByCanonicalProductId(String canonicalProductId);

    @Query("SELECT d FROM DealEntity d WHERE d.canonicalProductId = :canonicalId " +
            "AND d.validationStatus IN ('VALID', 'PRICE_CHANGED') " +
            "AND d.expiresAt > :now " +
            "ORDER BY d.finalPrice ASC")
    List<DealEntity> findFreshDealsByCanonicalId(@Param("canonicalId") String canonicalId, @Param("now") Instant now);

    @Query("SELECT d FROM DealEntity d WHERE d.validationStatus = 'VALID' AND d.expiresAt <= :now")
    List<DealEntity> findStaleDeals(@Param("now") Instant now);

    @Query("SELECT d FROM DealEntity d WHERE d.productId IN :productIds " +
            "AND d.validationStatus IN ('VALID', 'PRICE_CHANGED') " +
            "AND d.expiresAt > :now " +
            "ORDER BY d.finalPrice ASC")
    List<DealEntity> findFreshDealsForProductIds(@Param("productIds") List<UUID> productIds, @Param("now") Instant now);
}
