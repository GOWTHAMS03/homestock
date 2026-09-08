package com.homestock.modules.purchase.repository;

import com.homestock.modules.purchase.entity.PurchaseItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface PurchaseItemRepository extends JpaRepository<PurchaseItem, UUID> {
    List<PurchaseItem> findAllByPurchaseId(UUID purchaseId);

    List<PurchaseItem> findAllByInventoryItemId(UUID inventoryItemId);

    @Query("SELECT pi.itemName as name, COUNT(pi) as purchaseCount, SUM(pi.quantity) as totalQty " +
            "FROM PurchaseItem pi WHERE pi.purchase.home.id = :homeId " +
            "GROUP BY pi.itemName ORDER BY purchaseCount DESC")
    List<Object[]> getMostPurchasedItems(@Param("homeId") UUID homeId);

    @Query("SELECT pi.category.name as categoryName, SUM(pi.totalPrice) as total " +
            "FROM PurchaseItem pi WHERE pi.purchase.home.id = :homeId AND pi.category IS NOT NULL " +
            "GROUP BY pi.category.name ORDER BY total DESC")
    List<Object[]> getSpendingByCategory(@Param("homeId") UUID homeId);
}
