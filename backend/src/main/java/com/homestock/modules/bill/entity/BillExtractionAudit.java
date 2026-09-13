package com.homestock.modules.bill.entity;

import com.homestock.core.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.util.Map;

/**
 * Immutable audit record tracking each stage of the bill processing pipeline.
 * Every OCR, AI extraction, validation, and normalization step is recorded
 * for traceability, debugging, and future model improvement.
 */
@Entity
@Table(name = "bill_extraction_audit")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BillExtractionAudit extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bill_id", nullable = false)
    private PurchasedBill bill;

    @Column(name = "stage", nullable = false, length = 50)
    private String stage; // IMAGE_QUALITY, PREPROCESSING, OCR, AI_EXTRACTION, VALIDATION, NORMALIZATION, MATCHING

    @Column(name = "provider", length = 50)
    private String provider;

    @Column(name = "model", length = 100)
    private String model;

    @Column(name = "raw_input", columnDefinition = "TEXT")
    private String rawInput;

    @Column(name = "raw_output", columnDefinition = "TEXT")
    private String rawOutput;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "structured_output", columnDefinition = "jsonb")
    private Map<String, Object> structuredOutput;

    @Column(name = "confidence", precision = 5, scale = 2)
    private BigDecimal confidence;

    @Column(name = "duration_ms")
    private Integer durationMs;
}
