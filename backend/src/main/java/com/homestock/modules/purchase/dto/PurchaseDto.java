package com.homestock.modules.purchase.dto;

import com.homestock.modules.purchase.entity.Purchase;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseDto {
    private UUID id;
    private UUID homeId;
    private UUID storeId;
    private String storeName;
    private UUID recordedById;
    private String recordedByName;
    private LocalDate purchaseDate;
    private BigDecimal totalAmount;
    private String currency;
    private String receiptImageUrl;
    private String notes;
    private List<PurchaseItemDto> items;
    private Instant createdAt;

    public static PurchaseDto fromEntity(Purchase purchase) {
        if (purchase == null) return null;
        List<PurchaseItemDto> itemDtos = purchase.getItems() != null ?
                purchase.getItems().stream().map(PurchaseItemDto::fromEntity).collect(Collectors.toList()) : List.of();

        return PurchaseDto.builder()
                .id(purchase.getId())
                .homeId(purchase.getHome().getId())
                .storeId(purchase.getStore() != null ? purchase.getStore().getId() : null)
                .storeName(purchase.getStore() != null ? purchase.getStore().getName() : "Direct / General")
                .recordedById(purchase.getRecordedBy().getId())
                .recordedByName(purchase.getRecordedBy().getFullName())
                .purchaseDate(purchase.getPurchaseDate())
                .totalAmount(purchase.getTotalAmount())
                .currency(purchase.getCurrency())
                .receiptImageUrl(purchase.getReceiptImageUrl())
                .notes(purchase.getNotes())
                .items(itemDtos)
                .createdAt(purchase.getCreatedAt())
                .build();
    }
}
