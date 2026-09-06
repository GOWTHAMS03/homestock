package com.homestock.modules.category.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.home.entity.Home;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "categories", uniqueConstraints = {
        @UniqueConstraint(name = "uq_home_category_name", columnNames = {"home_id", "name"})
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Category extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "home_id")
    private Home home; // null = global default category

    @Column(name = "name", nullable = false, length = 80)
    private String name;

    @Builder.Default
    @Column(name = "icon", nullable = false, length = 60)
    private String icon = "category";

    @Builder.Default
    @Column(name = "color_hex", nullable = false, length = 10)
    private String colorHex = "#6366F1";

    @Builder.Default
    @Column(name = "display_order", nullable = false)
    private Integer displayOrder = 0;
}
