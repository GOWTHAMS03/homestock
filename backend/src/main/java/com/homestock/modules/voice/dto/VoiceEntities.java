package com.homestock.modules.voice.dto;

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
public class VoiceEntities {
    private String itemName;
    private BigDecimal quantity;
    private String unit;
    private String brand;
    private BigDecimal price;
    private String category;
    private String store;

    // Matched HomeStock inventory linkage
    private UUID matchedInventoryItemId;
    private String matchedInventoryItemName;
}
