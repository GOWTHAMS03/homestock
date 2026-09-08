package com.homestock.modules.consumption.repository;

import com.homestock.modules.consumption.entity.ConsumptionCycle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ConsumptionCycleRepository extends JpaRepository<ConsumptionCycle, UUID> {

    List<ConsumptionCycle> findAllByHomeIdAndInventoryItemIdOrderByCurrentPurchaseDateDesc(UUID homeId, UUID inventoryItemId);

    List<ConsumptionCycle> findAllByHomeIdOrderByCurrentPurchaseDateDesc(UUID homeId);

    long countByHomeIdAndInventoryItemId(UUID homeId, UUID inventoryItemId);
}
