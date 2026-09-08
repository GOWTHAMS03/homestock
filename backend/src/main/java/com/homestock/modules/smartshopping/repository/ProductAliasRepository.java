package com.homestock.modules.smartshopping.repository;

import com.homestock.modules.smartshopping.entity.ProductAlias;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ProductAliasRepository extends JpaRepository<ProductAlias, UUID> {

    List<ProductAlias> findByProductId(UUID productId);

    List<ProductAlias> findByAliasNameIgnoreCase(String aliasName);
}
