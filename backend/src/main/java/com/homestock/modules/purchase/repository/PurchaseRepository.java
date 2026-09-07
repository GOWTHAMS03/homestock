package com.homestock.modules.purchase.repository;

import com.homestock.modules.purchase.entity.Purchase;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PurchaseRepository extends JpaRepository<Purchase, UUID> {
    Page<Purchase> findAllByHomeIdOrderByPurchaseDateDescCreatedAtDesc(UUID homeId, Pageable pageable);
    Optional<Purchase> findByIdAndHomeId(UUID id, UUID homeId);

    @Query("SELECT SUM(p.totalAmount) FROM Purchase p WHERE p.home.id = :homeId AND p.purchaseDate >= :startDate")
    BigDecimal calculateTotalSpendingSince(@Param("homeId") UUID homeId, @Param("startDate") LocalDate startDate);

    @Query("SELECT p.store.name as storeName, SUM(p.totalAmount) as total " +
            "FROM Purchase p WHERE p.home.id = :homeId AND p.store IS NOT NULL " +
            "GROUP BY p.store.name ORDER BY total DESC")
    List<Object[]> getSpendingByStore(@Param("homeId") UUID homeId);

    List<Purchase> findByHomeIdAndUpdatedAtAfter(UUID homeId, java.time.Instant since);
}
