package com.homestock.modules.store.repository;

import com.homestock.modules.store.entity.Store;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface StoreRepository extends JpaRepository<Store, UUID> {
    List<Store> findAllByHomeIdOrderByNameAsc(UUID homeId);
    Optional<Store> findByIdAndHomeId(UUID id, UUID homeId);
    boolean existsByHomeIdAndNameIgnoreCase(UUID homeId, String name);

    @org.springframework.data.jpa.repository.Query("SELECT s FROM Store s WHERE s.home.id = :homeId AND s.updatedAt > :since ORDER BY s.name ASC")
    List<Store> findByHomeIdAndUpdatedAtAfter(@org.springframework.data.repository.query.Param("homeId") UUID homeId, @org.springframework.data.repository.query.Param("since") java.time.Instant since);
}
