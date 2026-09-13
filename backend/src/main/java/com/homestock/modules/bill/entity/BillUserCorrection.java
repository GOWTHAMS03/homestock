package com.homestock.modules.bill.entity;

import com.homestock.core.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

/**
 * Tracks user corrections to AI-extracted bill item fields.
 * Collects training data for future extraction improvements —
 * never used for automatic re-training without validation.
 */
@Entity
@Table(name = "bill_user_corrections")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BillUserCorrection extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bill_item_id", nullable = false)
    private PurchasedBillItem billItem;

    @Column(name = "field_name", nullable = false, length = 50)
    private String fieldName; // name, quantity, unit, unitPrice, finalPrice, etc.

    @Column(name = "ai_value", columnDefinition = "TEXT")
    private String aiValue;

    @Column(name = "user_value", columnDefinition = "TEXT")
    private String userValue;

    @Column(name = "merchant_name", length = 150)
    private String merchantName;
}
