package com.homestock.modules.home.dto;

import com.homestock.modules.home.entity.HomeRole;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class UpdateMemberRoleRequest {
    @NotNull(message = "Role is required")
    private HomeRole role;
}
