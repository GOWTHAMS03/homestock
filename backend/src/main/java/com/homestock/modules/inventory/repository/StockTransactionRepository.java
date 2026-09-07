package com.homestock.modules.inventory.repository;

import com.homestock.modules.inventory.entity.StockTransaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public interface StockTransactionRepository extends JpaRepository<StockTransaction, UUID> {
    Page<StockTransaction> findAllByItemIdOrderByCreatedAtDesc(UUID itemId, Pageable pageable);
    Page<StockTransaction> findAllByHomeIdOrderByCreatedAtDesc(UUID homeId, Pageable pageable);
    List<StockTransaction> findTop10ByHomeIdOrderByCreatedAtDesc(UUID homeId);

    @Query("SELECT t FROM StockTransaction t WHERE t.home.id = :homeId AND t.createdAt > :since ORDER BY t.createdAt DESC")
    List<StockTransaction> findByHomeIdAndCreatedAtAfter(@Param("homeId") UUID homeId, @Param("since") Instant since);
}
