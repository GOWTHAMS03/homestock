package com.homestock.modules.away.repository;

import com.homestock.modules.away.entity.PredictionFeedback;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PredictionFeedbackRepository extends JpaRepository<PredictionFeedback, UUID> {

    List<PredictionFeedback> findAllByInventoryItemIdOrderByCreatedAtDesc(UUID inventoryItemId);

    @Query("SELECT AVG(f.learningAdjustmentFactor) FROM PredictionFeedback f WHERE f.inventoryItem.id = :itemId")
    Optional<BigDecimal> findAverageAdjustmentFactorByItemId(@Param("itemId") UUID itemId);

    @Query("SELECT COUNT(f) FROM PredictionFeedback f WHERE f.inventoryItem.id = :itemId")
    long countByInventoryItemId(@Param("itemId") UUID itemId);
}
