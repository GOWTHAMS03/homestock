package com.homestock.modules.bill.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.store.entity.Store;
import com.homestock.modules.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "purchased_bills", uniqueConstraints = {
        @UniqueConstraint(name = "uq_purchased_bills_idempotency", columnNames = {"home_id", "idempotency_key"})
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchasedBill extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "home_id", nullable = false)
    private Home home;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "store_id")
    private Store store;

    @Column(name = "shop_name", length = 150)
    private String shopName;

    @Column(name = "bill_number", length = 100)
    private String billNumber;

    @Column(name = "bill_date", nullable = false)
    private LocalDate billDate;

    @Builder.Default
    @Column(name = "subtotal", precision = 12, scale = 2)
    private BigDecimal subtotal = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "tax_amount", precision = 12, scale = 2)
    private BigDecimal taxAmount = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "discount_amount", precision = 12, scale = 2)
    private BigDecimal discountAmount = BigDecimal.ZERO;

    @Column(name = "total_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal totalAmount;

    @Builder.Default
    @Column(name = "currency", nullable = false, length = 10)
    private String currency = "INR";

    @Column(name = "idempotency_key", nullable = false, length = 128)
    private String idempotencyKey;

    @Builder.Default
    @Column(name = "status", nullable = false, length = 30)
    private String status = "SCANNED"; // SCANNED, CONFIRMED

    @Column(name = "raw_ocr_text", columnDefinition = "TEXT")
    private String rawOcrText;

    @Column(name = "receipt_image_url", length = 512)
    private String receiptImageUrl;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recorded_by", nullable = false)
    private User recordedBy;

    @Column(name = "confirmed_at")
    private Instant confirmedAt;

    @Builder.Default
    @OneToMany(mappedBy = "bill", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<PurchasedBillItem> items = new ArrayList<>();
}
