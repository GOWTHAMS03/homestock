package com.homestock.modules.deals.repository;

import com.homestock.modules.deals.entity.NearbyShop;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface NearbyShopRepository extends JpaRepository<NearbyShop, UUID> {

    Optional<NearbyShop> findByOsmId(String osmId);

    List<NearbyShop> findByCityIgnoreCase(String city);

    List<NearbyShop> findByPostalCode(String postalCode);

    @Query("SELECT s FROM NearbyShop s WHERE s.isOpen = true")
    List<NearbyShop> findAllOpenShops();

    @Query("SELECT s FROM NearbyShop s WHERE " +
           "s.latitude BETWEEN :minLat AND :maxLat AND " +
           "s.longitude BETWEEN :minLon AND :maxLon AND " +
           "s.isOpen = true AND (s.active IS NULL OR s.active = true)")
    List<NearbyShop> findShopsInBoundingBox(
            @Param("minLat") BigDecimal minLat,
            @Param("maxLat") BigDecimal maxLat,
            @Param("minLon") BigDecimal minLon,
            @Param("maxLon") BigDecimal maxLon
    );

    @Query("SELECT s FROM NearbyShop s WHERE " +
           "LOWER(s.city) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(s.area) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "s.postalCode LIKE CONCAT('%', :query, '%')")
    List<NearbyShop> searchByLocationQuery(@Param("query") String query);

    // ═══ Shop Owner queries ═══

    Optional<NearbyShop> findByOwnerId(java.util.UUID ownerId);

    List<NearbyShop> findByVerificationStatus(String verificationStatus);

    @Query("SELECT s FROM NearbyShop s WHERE " +
           "s.latitude BETWEEN :minLat AND :maxLat AND " +
           "s.longitude BETWEEN :minLon AND :maxLon AND " +
           "s.verificationStatus = 'VERIFIED' AND " +
           "(s.active IS NULL OR s.active = true)")
    List<NearbyShop> findVerifiedShopsInBoundingBox(
            @Param("minLat") BigDecimal minLat,
            @Param("maxLat") BigDecimal maxLat,
            @Param("minLon") BigDecimal minLon,
            @Param("maxLon") BigDecimal maxLon
    );
}
