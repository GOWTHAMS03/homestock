package com.homestock.modules.deals.adapter;

import com.homestock.modules.deals.model.*;
import com.homestock.modules.smartshopping.provider.ProductSearchRequest;

import java.util.List;

/**
 * DealSourceAdapter:
 * Decoupled adapter interface for all external shopping providers.
 * Phase 5 — Deal Source Adapter Architecture.
 */
public interface DealSourceAdapter {

    DealSource getSource();

    boolean isEnabled();

    List<ExternalProduct> searchProducts(ProductSearchRequest request);

    ProductAvailability checkAvailability(ExternalProduct product);

    PriceDetails getCurrentPrice(ExternalProduct product);
}
