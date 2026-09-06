package com.homestock.modules.inventory.dto;

import com.homestock.modules.inventory.entity.StockTransaction;
import com.homestock.modules.inventory.entity.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockTransactionDto {
    private UUID id;
    private UUID itemId;
    private String itemName;
    private UUID userId;
    private String userName;
    private TransactionType transactionType;
    private BigDecimal quantityChange;
    private BigDecimal previousQuantity;
    private BigDecimal newQuantity;
    private String unit;
    private String reason;
    private Instant createdAt;

    public static StockTransactionDto fromEntity(StockTransaction tx) {
        if (tx == null) return null;
        return StockTransactionDto.builder()
                .id(tx.getId())
                .itemId(tx.getItem().getId())
                .itemName(tx.getItem().getName())
                .userId(tx.getUser().getId())
                .userName(tx.getUser().getFullName())
                .transactionType(tx.getTransactionType())
                .quantityChange(tx.getQuantityChange())
                .previousQuantity(tx.getPreviousQuantity())
                .newQuantity(tx.getNewQuantity())
                .unit(tx.getUnit())
                .reason(tx.getReason())
                .createdAt(tx.getCreatedAt())
                .build();
    }
}
