package com.homestock.modules.home.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Table(name = "room_members", uniqueConstraints = {
        @UniqueConstraint(name = "uq_room_member", columnNames = {"room_id", "user_id"})
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RoomMember extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "role", nullable = false, length = 20)
    private RoomMemberRole role;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    @Column(name = "status", nullable = false, length = 20)
    private RoomMemberStatus status = RoomMemberStatus.ACTIVE;

    @Builder.Default
    @Column(name = "joined_at", nullable = false)
    private Instant joinedAt = Instant.now();

    @Column(name = "last_seen_at")
    private Instant lastSeenAt;

    public boolean isActive() {
        return status == RoomMemberStatus.ACTIVE;
    }
}
