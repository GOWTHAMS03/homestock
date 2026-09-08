package com.homestock.modules.smartshopping.repository;

import com.homestock.modules.smartshopping.entity.ShoppingSessionItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ShoppingSessionItemRepository extends JpaRepository<ShoppingSessionItem, UUID> {

    List<ShoppingSessionItem> findBySessionId(UUID sessionId);

    void deleteBySessionId(UUID sessionId);
}
