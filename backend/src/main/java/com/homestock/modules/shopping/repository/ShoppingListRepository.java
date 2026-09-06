package com.homestock.modules.shopping.repository;

import com.homestock.modules.shopping.entity.ShoppingList;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface ShoppingListRepository extends JpaRepository<ShoppingList, UUID> {
    Optional<ShoppingList> findByHomeIdAndIsDefaultTrue(UUID homeId);
    Optional<ShoppingList> findByIdAndHomeId(UUID id, UUID homeId);
}
