package com.homestock.modules.smartshopping.repository;

import com.homestock.modules.smartshopping.entity.ProviderCapabilityEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ProviderCapabilityRepository extends JpaRepository<ProviderCapabilityEntity, UUID> {

    List<ProviderCapabilityEntity> findByProviderName(String providerName);

    void deleteByProviderName(String providerName);
}
