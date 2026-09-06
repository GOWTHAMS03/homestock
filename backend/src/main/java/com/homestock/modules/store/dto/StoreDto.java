package com.homestock.modules.store.dto;

import com.homestock.modules.store.entity.Store;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StoreDto {
    private UUID id;
    private UUID homeId;
    private String name;
    private String location;
    private String notes;

    public static StoreDto fromEntity(Store store) {
        if (store == null) return null;
        return StoreDto.builder()
                .id(store.getId())
                .homeId(store.getHome().getId())
                .name(store.getName())
                .location(store.getLocation())
                .notes(store.getNotes())
                .build();
    }
}
