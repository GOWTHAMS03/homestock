package com.homestock.modules.away.repository;

import com.homestock.modules.away.entity.AwayPrediction;
import com.homestock.modules.away.entity.PredictionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AwayPredictionRepository extends JpaRepository<AwayPrediction, UUID> {

    List<AwayPrediction> findAllBySummaryId(UUID summaryId);

    List<AwayPrediction> findAllBySummaryIdAndStatus(UUID summaryId, PredictionStatus status);

    @Query("SELECT p FROM AwayPrediction p WHERE p.summary.id = :summaryId ORDER BY p.confidence DESC")
    List<AwayPrediction> findBySummaryIdOrderByConfidenceDesc(@Param("summaryId") UUID summaryId);
}
