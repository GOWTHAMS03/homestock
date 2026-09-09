package com.homestock.modules.product.repository;

import com.homestock.modules.product.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProductRepository extends JpaRepository<Product, UUID> {

    Optional<Product> findByBarcode(String barcode);

    boolean existsByBarcode(String barcode);

    List<Product> findByNameContainingIgnoreCase(String name);

    @Query("SELECT p FROM Product p WHERE LOWER(p.normalizedName) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(p.brand) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<Product> searchProducts(@Param("query") String query);

    @Query("SELECT DISTINCT p FROM Product p LEFT JOIN p.identifiers i WHERE p.barcode = :val OR i.identifierValue = :val")
    List<Product> findByBarcodeOrIdentifierList(@Param("val") String val);

    default Optional<Product> findByBarcodeOrIdentifier(String val) {
        return findByBarcodeOrIdentifierList(val).stream().findFirst();
    }
}
