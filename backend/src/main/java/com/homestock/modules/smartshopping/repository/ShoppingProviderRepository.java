package com.homestock.modules.smartshopping.repository;

import com.homestock.modules.smartshopping.entity.ShoppingProviderEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ShoppingProviderRepository extends JpaRepository<ShoppingProviderEntity, UUID> {

    Optional<ShoppingProviderEntity> findByName(String name);

    List<ShoppingProviderEntity> findByEnabledTrue();

    List<ShoppingProviderEntity> findByProviderType(String providerType);
}
