package com.homestock.modules.home.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreateHomeRequest {
    @NotBlank(message = "Home name is required")
    @Size(min = 2, max = 120, message = "Home name must be between 2 and 120 characters")
    private String name;
}
