package com.homestock.modules.home.repository;

import com.homestock.modules.home.entity.Home;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface HomeRepository extends JpaRepository<Home, UUID> {
    Optional<Home> findByInviteCode(String inviteCode);
    boolean existsByInviteCode(String inviteCode);
}
