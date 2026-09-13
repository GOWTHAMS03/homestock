package com.homestock.modules.bill.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BillScanRequest {
    private String rawText;
    private String base64Image;
    private List<String> base64Images;
    private String storeName;
    private LocalDate billDate;
}
