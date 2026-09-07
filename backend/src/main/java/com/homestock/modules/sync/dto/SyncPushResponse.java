package com.homestock.modules.sync.dto;

import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SyncPushResponse {
    private List<SyncOperationResultDto> results;
}
