package com.homestock.modules.bill.repository;

import com.homestock.modules.bill.entity.BillUserCorrection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface BillUserCorrectionRepository extends JpaRepository<BillUserCorrection, UUID> {

    List<BillUserCorrection> findByBillItemId(UUID billItemId);

    @Query("SELECT c FROM BillUserCorrection c WHERE c.merchantName = :merchantName ORDER BY c.createdAt DESC")
    List<BillUserCorrection> findByMerchantName(@Param("merchantName") String merchantName);

    @Query("SELECT c FROM BillUserCorrection c WHERE c.fieldName = :fieldName ORDER BY c.createdAt DESC")
    List<BillUserCorrection> findByFieldName(@Param("fieldName") String fieldName);
}
