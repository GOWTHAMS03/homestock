package com.homestock.modules.product.repository;

import com.homestock.modules.product.entity.ProductIdentifier;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProductCatalogIdentifierRepository extends JpaRepository<ProductIdentifier, UUID> {

    Optional<ProductIdentifier> findByIdentifierValue(String identifierValue);

    List<ProductIdentifier> findByProductId(UUID productId);

    boolean existsByIdentifierValue(String identifierValue);
}
