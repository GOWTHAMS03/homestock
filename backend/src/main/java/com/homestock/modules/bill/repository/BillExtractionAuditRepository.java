package com.homestock.modules.bill.repository;

import com.homestock.modules.bill.entity.BillExtractionAudit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface BillExtractionAuditRepository extends JpaRepository<BillExtractionAudit, UUID> {

    List<BillExtractionAudit> findByBillIdOrderByCreatedAtAsc(UUID billId);

    List<BillExtractionAudit> findByBillIdAndStage(UUID billId, String stage);
}
