package com.homestock.modules.deals.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.product.entity.Product;
import com.homestock.modules.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

/**
 * User feedback on product matching for continuous scoring improvement.
 */
@Entity
@Table(name = "product_match_feedback")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductMatchFeedback extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id")
    private Product product;

    @Column(name = "candidate_title", nullable = false, length = 300)
    private String candidateTitle;

    @Column(name = "is_correct_match", nullable = false)
    private Boolean isCorrectMatch;

    @Column(name = "feedback_note", columnDefinition = "TEXT")
    private String feedbackNote;
}
