package com.homestock.modules.deals.repository;

import com.homestock.modules.deals.entity.DealPriceHistoryEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface DealPriceHistoryRepository extends JpaRepository<DealPriceHistoryEntity, UUID> {

    List<DealPriceHistoryEntity> findByDealIdOrderByDetectedAtDesc(UUID dealId);

    List<DealPriceHistoryEntity> findTop50ByOrderByDetectedAtDesc();
}
