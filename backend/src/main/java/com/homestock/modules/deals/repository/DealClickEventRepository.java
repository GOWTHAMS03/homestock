package com.homestock.modules.deals.repository;

import com.homestock.modules.deals.entity.DealClickEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface DealClickEventRepository extends JpaRepository<DealClickEvent, UUID> {

    List<DealClickEvent> findByUserIdOrderByClickedAtDesc(UUID userId);

    long countByProvider(String provider);
}
