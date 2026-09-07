package com.homestock.modules.category.repository;

import com.homestock.modules.category.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CategoryRepository extends JpaRepository<Category, UUID> {
    @Query("SELECT c FROM Category c WHERE c.home.id = :homeId OR c.home IS NULL ORDER BY c.displayOrder ASC, c.name ASC")
    List<Category> findAllByHomeIdOrGlobal(@Param("homeId") UUID homeId);

    Optional<Category> findByHomeIdAndNameIgnoreCase(UUID homeId, String name);
    boolean existsByHomeIdAndNameIgnoreCase(UUID homeId, String name);

    @Query("SELECT c FROM Category c WHERE (c.home.id = :homeId OR c.home IS NULL) AND c.updatedAt > :since ORDER BY c.displayOrder ASC, c.name ASC")
    List<Category> findByHomeIdAndUpdatedAtAfter(@Param("homeId") UUID homeId, @Param("since") java.time.Instant since);
}
