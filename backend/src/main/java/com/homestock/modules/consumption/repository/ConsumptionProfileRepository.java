package com.homestock.modules.consumption.repository;

import com.homestock.modules.consumption.entity.ConsumptionProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ConsumptionProfileRepository extends JpaRepository<ConsumptionProfile, UUID> {

    Optional<ConsumptionProfile> findByHomeIdAndInventoryItemId(UUID homeId, UUID inventoryItemId);

    List<ConsumptionProfile> findAllByHomeId(UUID homeId);

    void deleteAllByHomeIdAndInventoryItemId(UUID homeId, UUID inventoryItemId);
}
