package com.homestock.modules.bill.repository;

import com.homestock.modules.bill.entity.PurchasedBillItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface PurchasedBillItemRepository extends JpaRepository<PurchasedBillItem, UUID> {

    List<PurchasedBillItem> findByBillId(UUID billId);

    @Query("SELECT COUNT(i), COALESCE(SUM(i.quantity), 0) FROM PurchasedBillItem i " +
           "WHERE i.bill.home.id = :homeId AND i.bill.billDate >= :startDate " +
           "AND i.bill.billDate <= :endDate AND i.bill.status = 'CONFIRMED'")
    List<Object[]> getItemCountsInPeriod(
            @Param("homeId") UUID homeId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );

    @Query("SELECT COALESCE(cat.name, 'Other'), SUM(i.finalPrice), COUNT(i), SUM(i.quantity) " +
           "FROM PurchasedBillItem i " +
           "LEFT JOIN i.inventoryItem inv " +
           "LEFT JOIN inv.category cat " +
           "WHERE i.bill.home.id = :homeId AND i.bill.billDate >= :startDate " +
           "AND i.bill.billDate <= :endDate AND i.bill.status = 'CONFIRMED' " +
           "GROUP BY COALESCE(cat.name, 'Other') ORDER BY SUM(i.finalPrice) DESC")
    List<Object[]> getCategorySpendingBreakdown(
            @Param("homeId") UUID homeId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );
}
