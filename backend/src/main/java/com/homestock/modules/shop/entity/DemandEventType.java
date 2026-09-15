package com.homestock.modules.shop.entity;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * Categorized customer interaction types that produce demand signals.
 * Each interaction has a configurable base weight reflecting purchase intent.
 */
@Getter
@RequiredArgsConstructor
public enum DemandEventType {

    SEARCH(1.0, "Customer Catalog Search"),
    PRODUCT_VIEW(2.0, "Product Detail View"),
    BARCODE_SCAN(3.0, "Barcode / In-Store Scan"),
    SHOPPING_LIST_ADD(4.0, "Added to Shopping List"),
    VOICE_ADD(4.0, "Voice Shopping Command"),
    NEARBY_SEARCH(5.0, "Nearby Store Product Discovery"),
    SHOP_PRODUCT_VIEW(2.5, "Shop Catalog Item View");

    private final double baseWeight;
    private final String description;
}
