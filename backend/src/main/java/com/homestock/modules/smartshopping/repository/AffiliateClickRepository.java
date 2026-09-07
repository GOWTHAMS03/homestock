package com.homestock.modules.smartshopping.repository;

import com.homestock.modules.smartshopping.entity.AffiliateClick;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface AffiliateClickRepository extends JpaRepository<AffiliateClick, UUID> {
}
