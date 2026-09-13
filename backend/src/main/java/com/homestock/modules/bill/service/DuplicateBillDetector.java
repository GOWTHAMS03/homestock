package com.homestock.modules.bill.service;

import com.homestock.modules.bill.entity.PurchasedBill;
import com.homestock.modules.bill.repository.PurchasedBillRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDate;
import java.util.HexFormat;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class DuplicateBillDetector {

    private final PurchasedBillRepository billRepository;

    public DuplicateBillDetector(PurchasedBillRepository billRepository) {
        this.billRepository = billRepository;
    }

    public String generateIdempotencyKey(UUID homeId, String shopName, String billNumber, LocalDate billDate, BigDecimal totalAmount) {
        String cleanShop = sanitize(shopName) != null ? sanitize(shopName).toLowerCase() : "unknown";
        String cleanNo = sanitize(billNumber) != null ? sanitize(billNumber).toLowerCase() : "none";
        String cleanDate = billDate != null ? billDate.toString() : "nodate";
        String cleanTotal = totalAmount != null ? totalAmount.setScale(2).toString() : "0.00";

        String raw = homeId.toString() + ":" + cleanShop + ":" + cleanNo + ":" + cleanDate + ":" + cleanTotal;
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(raw.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (Exception e) {
            return UUID.nameUUIDFromBytes(raw.getBytes(StandardCharsets.UTF_8)).toString();
        }
    }

    public DuplicateCheckResult checkDuplicate(UUID homeId, String shopName, String billNumber, LocalDate billDate, BigDecimal totalAmount) {
        String safeShop = sanitize(shopName);
        String safeNo = sanitize(billNumber);
        String key = generateIdempotencyKey(homeId, safeShop, safeNo, billDate, totalAmount);

        // 1. Exact Idempotent duplicate check
        Optional<PurchasedBill> exactMatch = billRepository.findByHomeIdAndIdempotencyKey(homeId, key);
        if (exactMatch.isPresent()) {
            PurchasedBill b = exactMatch.get();
            return new DuplicateCheckResult(
                    true,
                    true,
                    b.getId(),
                    "Exact duplicate bill detected (" + b.getShopName() + ", " + b.getBillDate() + ", ₹" + b.getTotalAmount() + ")"
            );
        }

        // 2. Soft duplicate check (same shop + date + amount)
        if (safeShop != null && !safeShop.isBlank() && billDate != null && totalAmount != null) {
            List<PurchasedBill> potentials = billRepository.findPotentialDuplicates(homeId, safeShop, billDate, totalAmount);
            if (!potentials.isEmpty()) {
                PurchasedBill b = potentials.get(0);
                return new DuplicateCheckResult(
                        true,
                        false,
                        b.getId(),
                        "Possible duplicate bill detected from " + b.getShopName() + " on " + b.getBillDate() + " for ₹" + b.getTotalAmount()
                );
            }
        }

        return new DuplicateCheckResult(false, false, null, null);
    }

    private String sanitize(String input) {
        if (input == null) return null;
        String s = input.replace("\u0000", "").replaceAll("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]", "").trim();
        return s.isEmpty() ? null : s;
    }

    public record DuplicateCheckResult(
            boolean isDuplicate,
            boolean isExactMatch,
            UUID existingBillId,
            String warningMessage
    ) {}
}
