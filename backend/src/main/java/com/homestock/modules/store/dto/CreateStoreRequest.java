package com.homestock.modules.store.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreateStoreRequest {
    @NotBlank(message = "Store name is required")
    @Size(min = 1, max = 120)
    private String name;

    private String location;
    private String notes;
}
