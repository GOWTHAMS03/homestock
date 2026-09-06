package com.homestock.modules.store.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.home.entity.Home;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "stores")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Store extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "home_id", nullable = false)
    private Home home;

    @Column(name = "name", nullable = false, length = 120)
    private String name;

    @Column(name = "location", length = 200)
    private String location;

    @Column(name = "notes")
    private String notes;
}
