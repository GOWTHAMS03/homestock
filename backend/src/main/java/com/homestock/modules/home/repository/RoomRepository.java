package com.homestock.modules.home.repository;

import com.homestock.modules.home.entity.Room;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RoomRepository extends JpaRepository<Room, UUID> {
    Optional<Room> findByRoomCode(String roomCode);
    boolean existsByRoomCode(String roomCode);

    @Query("SELECT r FROM Room r JOIN r.members m WHERE m.user.id = :userId AND m.status = 'ACTIVE' AND r.status = 'ACTIVE'")
    List<Room> findActiveRoomsByUserId(@Param("userId") UUID userId);
}
