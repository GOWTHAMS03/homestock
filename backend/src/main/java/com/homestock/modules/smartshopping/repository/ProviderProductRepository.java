package com.homestock.modules.smartshopping.repository;

import com.homestock.modules.smartshopping.entity.ProviderProduct;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProviderProductRepository extends JpaRepository<ProviderProduct, UUID> {

    Optional<ProviderProduct> findByProviderNameAndProviderProductId(String providerName, String providerProductId);

    List<ProviderProduct> findByProductId(UUID productId);
}
