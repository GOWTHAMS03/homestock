package com.homestock.modules.home.repository;

import com.homestock.modules.home.entity.RoomMember;
import com.homestock.modules.home.entity.RoomMemberStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RoomMemberRepository extends JpaRepository<RoomMember, UUID> {
    Optional<RoomMember> findByRoomIdAndUserId(UUID roomId, UUID userId);
    List<RoomMember> findByRoomIdAndStatus(UUID roomId, RoomMemberStatus status);
    List<RoomMember> findByUserIdAndStatus(UUID userId, RoomMemberStatus status);

    @Query("SELECT CASE WHEN COUNT(rm) > 0 THEN true ELSE false END FROM RoomMember rm WHERE rm.room.id = :roomId AND rm.user.id = :userId AND rm.status = 'ACTIVE'")
    boolean existsActiveByRoomIdAndUserId(@Param("roomId") UUID roomId, @Param("userId") UUID userId);
}
