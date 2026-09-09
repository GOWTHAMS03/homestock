package com.homestock.modules.product.provider;

import com.homestock.modules.product.dto.ProductDto;
import com.homestock.modules.product.entity.Product;
import com.homestock.modules.product.repository.ProductRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class InternalProductProvider implements ProductDataProvider {

    private final ProductRepository productRepository;

    @Override
    public String getProviderName() {
        return "INTERNAL";
    }

    @Override
    public int getPriority() {
        return 1;
    }

    @Override
    public Optional<ProductDto> findByBarcode(String barcode) {
        return productRepository.findByBarcodeOrIdentifier(barcode).map(this::toDto);
    }

    @Override
    public List<ProductDto> searchByName(String query) {
        return productRepository.searchProducts(query).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public ProductDto toDto(Product p) {
        return ProductDto.builder()
                .id(p.getId())
                .barcode(p.getBarcode())
                .barcodeType(p.getBarcodeType())
                .name(p.getName())
                .normalizedName(p.getNormalizedName())
                .brand(p.getBrand())
                .categoryId(p.getCategory() != null ? p.getCategory().getId() : null)
                .categoryName(p.getCategoryName())
                .packageSize(p.getPackageSize())
                .unit(p.getUnit())
                .packageUnit(p.getPackageUnit())
                .description(p.getDescription())
                .imageUrl(p.getImageUrl())
                .source(p.getSource())
                .build();
    }
}
