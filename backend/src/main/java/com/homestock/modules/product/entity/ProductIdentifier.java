package com.homestock.modules.product.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

@Entity(name = "ProductBarcodeIdentifier")
@Table(name = "product_identifiers")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductIdentifier {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    @Column(name = "identifier_type", nullable = false, length = 30)
    private String identifierType;

    @Column(name = "identifier_value", nullable = false, length = 100)
    private String identifierValue;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
}
