package com.homestock.modules.auth.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "auth_identities", uniqueConstraints = {
        @UniqueConstraint(name = "uq_auth_identity", columnNames = {"provider", "provider_subject"})
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthIdentity extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "provider", nullable = false, length = 50)
    private String provider; // 'LOCAL', 'GOOGLE'

    @Column(name = "provider_subject", nullable = false, length = 255)
    private String providerSubject; // Google 'sub' or local email/username
}
