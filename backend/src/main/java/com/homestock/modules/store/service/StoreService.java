package com.homestock.modules.store.service;

import com.homestock.core.exception.BusinessRuleException;
import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.store.dto.CreateStoreRequest;
import com.homestock.modules.store.dto.StoreDto;
import com.homestock.modules.store.entity.Store;
import com.homestock.modules.store.repository.StoreRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StoreService {

    private final StoreRepository storeRepository;
    private final HomeRepository homeRepository;

    @Transactional(readOnly = true)
    public List<StoreDto> getStoresForHome(UUID homeId) {
        return storeRepository.findAllByHomeIdOrderByNameAsc(homeId).stream()
                .map(StoreDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public StoreDto createStore(UUID homeId, CreateStoreRequest request) {
        Home home = homeRepository.findById(homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Home not found"));

        if (storeRepository.existsByHomeIdAndNameIgnoreCase(homeId, request.getName().trim())) {
            throw new BusinessRuleException("Store with this name already exists");
        }

        Store store = Store.builder()
                .home(home)
                .name(request.getName().trim())
                .location(request.getLocation() != null ? request.getLocation().trim() : null)
                .notes(request.getNotes())
                .build();

        return StoreDto.fromEntity(storeRepository.save(store));
    }
}
