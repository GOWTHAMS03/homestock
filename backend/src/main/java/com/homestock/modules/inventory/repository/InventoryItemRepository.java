package com.homestock.modules.inventory.repository;

import com.homestock.modules.inventory.entity.InventoryItem;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;

@Repository
public interface InventoryItemRepository extends JpaRepository<InventoryItem, UUID>, JpaSpecificationExecutor<InventoryItem> {

    Optional<InventoryItem> findByIdAndHomeId(UUID id, UUID homeId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT i FROM InventoryItem i WHERE i.id = :id AND i.home.id = :homeId")
    Optional<InventoryItem> findWithLockByIdAndHomeId(@Param("id") UUID id, @Param("homeId") UUID homeId);

    List<InventoryItem> findAllByHomeIdAndIsArchivedFalseOrderByNameAsc(UUID homeId);

    List<InventoryItem> findAllByHomeIdOrderByNameAsc(UUID homeId);

    @Query("SELECT i FROM InventoryItem i WHERE i.home.id = :homeId AND i.isArchived = false AND i.quantity <= i.minimumQuantity")
    List<InventoryItem> findLowStockItems(@Param("homeId") UUID homeId);

    @Query("SELECT i FROM InventoryItem i WHERE i.home.id = :homeId AND i.isArchived = false AND i.quantity = 0")
    List<InventoryItem> findOutOfStockItems(@Param("homeId") UUID homeId);

    @Query("SELECT i FROM InventoryItem i WHERE i.home.id = :homeId AND i.isArchived = false " +
            "AND i.expiryDate IS NOT NULL AND i.expiryDate <= :untilDate AND i.expiryDate >= :fromDate " +
            "ORDER BY i.expiryDate ASC")
    List<InventoryItem> findExpiringSoonItems(
            @Param("homeId") UUID homeId,
            @Param("fromDate") LocalDate fromDate,
            @Param("untilDate") LocalDate untilDate);

    @Query("SELECT i FROM InventoryItem i WHERE i.home.id = :homeId AND i.isArchived = false " +
            "AND i.expiryDate IS NOT NULL AND i.expiryDate < :today")
    List<InventoryItem> findExpiredItems(@Param("homeId") UUID homeId, @Param("today") LocalDate today);

    long countByHomeIdAndIsArchivedFalse(UUID homeId);

    @Query("SELECT COUNT(i) FROM InventoryItem i WHERE i.home.id = :homeId AND i.isArchived = false AND i.quantity <= i.minimumQuantity AND i.quantity > 0")
    long countLowStock(@Param("homeId") UUID homeId);

    @Query("SELECT COUNT(i) FROM InventoryItem i WHERE i.home.id = :homeId AND i.isArchived = false AND i.quantity = 0")
    long countOutOfStock(@Param("homeId") UUID homeId);

    List<InventoryItem> findByHomeIdAndUpdatedAtAfter(UUID homeId, Instant since);

    Optional<InventoryItem> findByHomeIdAndBarcodeAndIsArchivedFalse(UUID homeId, String barcode);

    Optional<InventoryItem> findByHomeIdAndProductIdAndIsArchivedFalse(UUID homeId, UUID productId);
}
