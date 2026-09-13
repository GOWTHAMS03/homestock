package com.homestock.modules.deals.repository;

import com.homestock.modules.deals.entity.UserLocationPreference;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserLocationPreferenceRepository extends JpaRepository<UserLocationPreference, UUID> {

    Optional<UserLocationPreference> findByUserId(UUID userId);

    void deleteByUserId(UUID userId);
}
