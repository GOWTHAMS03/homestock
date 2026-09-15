package com.homestock.modules.shop.repository;

import com.homestock.modules.shop.entity.SubscriptionPlan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SubscriptionPlanRepository extends JpaRepository<SubscriptionPlan, UUID> {
    Optional<SubscriptionPlan> findByName(String name);
    List<SubscriptionPlan> findByIsActiveTrueOrderBySortOrderAsc();
}
