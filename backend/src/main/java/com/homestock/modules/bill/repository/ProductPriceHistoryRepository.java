package com.homestock.modules.bill.repository;

import com.homestock.modules.bill.entity.ProductPriceHistory;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Repository
public interface ProductPriceHistoryRepository extends JpaRepository<ProductPriceHistory, UUID> {

    List<ProductPriceHistory> findByHomeIdAndProductIdOrderByPurchaseDateDesc(UUID homeId, UUID productId, Pageable pageable);

    List<ProductPriceHistory> findByHomeIdAndInventoryItemIdOrderByPurchaseDateDesc(UUID homeId, UUID itemId, Pageable pageable);

    @Query("SELECT AVG(h.standardUnitPrice), MIN(h.standardUnitPrice), MAX(h.standardUnitPrice) " +
           "FROM ProductPriceHistory h WHERE h.home.id = :homeId AND h.product.id = :productId")
    List<Object[]> getPriceStatsByProduct(@Param("homeId") UUID homeId, @Param("productId") UUID productId);

    @Query("SELECT AVG(h.standardUnitPrice), MIN(h.standardUnitPrice), MAX(h.standardUnitPrice) " +
           "FROM ProductPriceHistory h WHERE h.home.id = :homeId AND h.inventoryItem.id = :itemId")
    List<Object[]> getPriceStatsByInventoryItem(@Param("homeId") UUID homeId, @Param("itemId") UUID itemId);

    @Query("SELECT h.storeName, AVG(h.standardUnitPrice), MIN(h.standardUnitPrice), MAX(h.standardUnitPrice), COUNT(h) " +
           "FROM ProductPriceHistory h WHERE h.home.id = :homeId AND h.product.id = :productId " +
           "GROUP BY h.storeName ORDER BY AVG(h.standardUnitPrice) ASC")
    List<Object[]> getStorePriceComparison(@Param("homeId") UUID homeId, @Param("productId") UUID productId);

    @Query("SELECT h.storeName, AVG(h.standardUnitPrice), MIN(h.standardUnitPrice), MAX(h.standardUnitPrice), COUNT(h) " +
           "FROM ProductPriceHistory h WHERE h.home.id = :homeId AND h.inventoryItem.id = :itemId " +
           "GROUP BY h.storeName ORDER BY AVG(h.standardUnitPrice) ASC")
    List<Object[]> getStorePriceComparisonByItem(@Param("homeId") UUID homeId, @Param("itemId") UUID itemId);

    @Query("SELECT h FROM ProductPriceHistory h WHERE h.home.id = :homeId " +
           "ORDER BY h.purchaseDate DESC")
    List<ProductPriceHistory> findRecentPriceChanges(@Param("homeId") UUID homeId, Pageable pageable);
}
