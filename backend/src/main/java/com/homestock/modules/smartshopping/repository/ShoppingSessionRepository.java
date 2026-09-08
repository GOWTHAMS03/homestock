package com.homestock.modules.smartshopping.repository;

import com.homestock.modules.smartshopping.entity.ShoppingSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ShoppingSessionRepository extends JpaRepository<ShoppingSession, UUID> {

    List<ShoppingSession> findByHomeIdOrderByStartedAtDesc(UUID homeId);

    Optional<ShoppingSession> findFirstByHomeIdAndStatusOrderByStartedAtDesc(UUID homeId, String status);
}
