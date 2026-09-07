package com.homestock.modules.sync.repository;

import com.homestock.modules.sync.entity.ProcessedOperation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProcessedOperationRepository extends JpaRepository<ProcessedOperation, UUID> {
    Optional<ProcessedOperation> findByOperationId(String operationId);
    boolean existsByOperationId(String operationId);
}
