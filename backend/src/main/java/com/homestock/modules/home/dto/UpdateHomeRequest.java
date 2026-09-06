package com.homestock.modules.home.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateHomeRequest {
    @NotBlank(message = "Home name is required")
    @Size(min = 2, max = 120)
    private String name;
}
