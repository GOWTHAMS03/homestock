package com.homestock.modules.product.provider;

import com.homestock.modules.product.dto.ProductDto;

import java.util.List;
import java.util.Optional;

public interface ProductDataProvider {

    String getProviderName();

    int getPriority();

    Optional<ProductDto> findByBarcode(String barcode);

    List<ProductDto> searchByName(String query);
}
