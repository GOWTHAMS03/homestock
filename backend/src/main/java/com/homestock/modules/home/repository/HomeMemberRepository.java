package com.homestock.modules.home.repository;

import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.entity.HomeMember;
import com.homestock.modules.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface HomeMemberRepository extends JpaRepository<HomeMember, UUID> {
    Optional<HomeMember> findByHomeIdAndUserId(UUID homeId, UUID userId);
    List<HomeMember> findAllByUserId(UUID userId);
    List<HomeMember> findAllByHomeId(UUID homeId);
    boolean existsByHomeIdAndUserId(UUID homeId, UUID userId);
    void deleteByHomeAndUser(Home home, User user);
}
