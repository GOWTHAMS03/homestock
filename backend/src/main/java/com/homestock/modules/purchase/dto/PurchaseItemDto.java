package com.homestock.modules.purchase.dto;

import com.homestock.modules.purchase.entity.PurchaseItem;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseItemDto {
    private UUID id;
    private UUID inventoryItemId;
    private String itemName;
    private UUID categoryId;
    private String categoryName;
    private BigDecimal quantity;
    private String unit;
    private BigDecimal unitPrice;
    private BigDecimal totalPrice;

    public static PurchaseItemDto fromEntity(PurchaseItem item) {
        if (item == null) return null;
        return PurchaseItemDto.builder()
                .id(item.getId())
                .inventoryItemId(item.getInventoryItem() != null ? item.getInventoryItem().getId() : null)
                .itemName(item.getItemName())
                .categoryId(item.getCategory() != null ? item.getCategory().getId() : null)
                .categoryName(item.getCategory() != null ? item.getCategory().getName() : null)
                .quantity(item.getQuantity())
                .unit(item.getUnit())
                .unitPrice(item.getUnitPrice())
                .totalPrice(item.getTotalPrice())
                .build();
    }
}
