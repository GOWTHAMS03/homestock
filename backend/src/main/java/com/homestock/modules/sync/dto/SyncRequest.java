package com.homestock.modules.sync.dto;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SyncRequest {

    @NotNull
    private UUID homeId;

    private List<SyncOperationDto> operations;
}
