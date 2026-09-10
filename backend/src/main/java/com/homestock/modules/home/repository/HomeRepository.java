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

    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("SELECT h FROM Home h WHERE h.id = :id")
    Optional<Home> findWithLockById(@org.springframework.data.repository.query.Param("id") UUID id);
}
