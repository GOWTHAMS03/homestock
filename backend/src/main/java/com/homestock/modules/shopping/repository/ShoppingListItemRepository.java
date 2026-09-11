package com.homestock.modules.shopping.repository;

import com.homestock.modules.shopping.entity.ShoppingListItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ShoppingListItemRepository extends JpaRepository<ShoppingListItem, UUID> {

    List<ShoppingListItem> findAllByShoppingListIdOrderByIsCompletedAscCreatedAtDesc(UUID shoppingListId);

    @Query("SELECT s FROM ShoppingListItem s WHERE s.shoppingList.id = :listId AND s.inventoryItem.id = :itemId AND s.isCompleted = false")
    Optional<ShoppingListItem> findActiveItemByInventoryItemId(@Param("listId") UUID listId, @Param("itemId") UUID itemId);

    long countByShoppingListIdAndIsCompletedFalse(UUID shoppingListId);

    @Query("SELECT s FROM ShoppingListItem s WHERE s.shoppingList.id = :listId AND s.isCompleted = true")
    List<ShoppingListItem> findAllCompletedByShoppingListId(@Param("listId") UUID listId);

    @Modifying
    @Query("DELETE FROM ShoppingListItem s WHERE s.shoppingList.id = :listId AND s.isCompleted = true")
    void deleteAllCompletedByShoppingListId(@Param("listId") UUID listId);

    @Query("SELECT s FROM ShoppingListItem s WHERE s.shoppingList.home.id = :homeId AND s.isCompleted = false")
    List<ShoppingListItem> findPendingItemsByHomeId(@Param("homeId") UUID homeId);

    @Query("SELECT s FROM ShoppingListItem s WHERE s.shoppingList.home.id = :homeId AND s.updatedAt > :since")
    List<ShoppingListItem> findByHomeIdAndUpdatedAtAfter(@Param("homeId") UUID homeId, @Param("since") java.time.Instant since);

    @Query("SELECT s FROM ShoppingListItem s WHERE s.shoppingList.home.id = :homeId AND s.barcode = :barcode AND s.isCompleted = false")
    Optional<ShoppingListItem> findActiveItemByHomeIdAndBarcode(@Param("homeId") UUID homeId, @Param("barcode") String barcode);

    @Query("SELECT s FROM ShoppingListItem s WHERE s.shoppingList.home.id = :homeId AND s.inventoryItem.id = :itemId AND s.isCompleted = false")
    Optional<ShoppingListItem> findActiveItemByHomeIdAndInventoryItemId(@Param("homeId") UUID homeId, @Param("itemId") UUID itemId);

    @Query("SELECT MAX(s.createdAt) FROM ShoppingListItem s WHERE s.addedBy.id = :userId")
    Optional<java.time.Instant> findLatestAddedTimeByUserId(@Param("userId") UUID userId);
}
