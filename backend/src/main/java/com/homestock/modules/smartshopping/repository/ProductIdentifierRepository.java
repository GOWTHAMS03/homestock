package com.homestock.modules.smartshopping.repository;

import com.homestock.modules.smartshopping.entity.ProductIdentifier;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProductIdentifierRepository extends JpaRepository<ProductIdentifier, UUID> {

    List<ProductIdentifier> findByProductId(UUID productId);

    Optional<ProductIdentifier> findByIdentifierTypeAndIdentifierValue(String identifierType, String identifierValue);
}
