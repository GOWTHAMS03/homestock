package com.homestock.modules.bill.repository;

import com.homestock.modules.bill.entity.PurchasedBill;
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
public interface PurchasedBillRepository extends JpaRepository<PurchasedBill, UUID> {

    Page<PurchasedBill> findByHomeIdOrderByBillDateDesc(UUID homeId, Pageable pageable);

    Optional<PurchasedBill> findByHomeIdAndIdempotencyKey(UUID homeId, String idempotencyKey);

    @Query("SELECT b FROM PurchasedBill b WHERE b.home.id = :homeId " +
           "AND LOWER(TRIM(b.shopName)) = LOWER(TRIM(:shopName)) " +
           "AND b.billDate = :billDate " +
           "AND ABS(b.totalAmount - :totalAmount) < 0.05")
    List<PurchasedBill> findPotentialDuplicates(
            @Param("homeId") UUID homeId,
            @Param("shopName") String shopName,
            @Param("billDate") LocalDate billDate,
            @Param("totalAmount") BigDecimal totalAmount
    );

    @Query("SELECT COUNT(b) FROM PurchasedBill b WHERE b.home.id = :homeId " +
           "AND b.billDate >= :startDate AND b.billDate <= :endDate AND b.status = 'CONFIRMED'")
    Long countBillsInPeriod(
            @Param("homeId") UUID homeId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );

    @Query("SELECT COALESCE(SUM(b.totalAmount), 0) FROM PurchasedBill b WHERE b.home.id = :homeId " +
           "AND b.billDate >= :startDate AND b.billDate <= :endDate AND b.status = 'CONFIRMED'")
    BigDecimal calculateTotalSpendInPeriod(
            @Param("homeId") UUID homeId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );

    @Query("SELECT b.shopName, SUM(b.totalAmount), COUNT(b) FROM PurchasedBill b " +
           "WHERE b.home.id = :homeId AND b.billDate >= :startDate AND b.billDate <= :endDate " +
           "AND b.status = 'CONFIRMED' AND b.shopName IS NOT NULL " +
           "GROUP BY b.shopName ORDER BY SUM(b.totalAmount) DESC")
    List<Object[]> getShopSpendingBreakdown(
            @Param("homeId") UUID homeId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );
}
