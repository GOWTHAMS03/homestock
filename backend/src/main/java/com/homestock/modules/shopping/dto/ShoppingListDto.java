package com.homestock.modules.shopping.dto;

import com.homestock.modules.shopping.entity.ShoppingList;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShoppingListDto {
    private UUID id;
    private UUID homeId;
    private String name;
    private Boolean isDefault;
    private long pendingCount;
    private long completedCount;
    private List<ShoppingListItemDto> items;

    public static ShoppingListDto fromEntity(ShoppingList list, List<ShoppingListItemDto> items) {
        if (list == null) return null;
        long pending = items.stream().filter(i -> !Boolean.TRUE.equals(i.getIsCompleted())).count();
        long completed = items.stream().filter(i -> Boolean.TRUE.equals(i.getIsCompleted())).count();

        return ShoppingListDto.builder()
                .id(list.getId())
                .homeId(list.getHome().getId())
                .name(list.getName())
                .isDefault(list.getIsDefault())
                .pendingCount(pending)
                .completedCount(completed)
                .items(items)
                .build();
    }
}
