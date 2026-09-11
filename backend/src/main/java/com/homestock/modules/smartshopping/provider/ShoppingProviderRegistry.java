package com.homestock.modules.smartshopping.provider;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * Pluggable registry for all registered shopping providers.
 * <p>
 * Decouples controllers and comparison services from concrete provider implementations.
 * Enables adding new providers dynamically by registering them as Spring beans.
 */
@Component
public class ShoppingProviderRegistry {

    private static final Logger log = LoggerFactory.getLogger(ShoppingProviderRegistry.class);

    private final Map<String, ShoppingProvider> providerMap = new ConcurrentHashMap<>();

    public ShoppingProviderRegistry(List<ShoppingProvider> providers) {
        for (ShoppingProvider provider : providers) {
            String name = provider.getProviderName().toUpperCase();
            providerMap.put(name, provider);
            log.info("[ProviderRegistry] Registered provider '{}' (Enabled: {}, Capabilities: {})",
                    name, provider.isEnabled(), provider.getCapabilities());
        }
    }

    /**
     * Retrieve provider by normalized name (e.g. "AMAZON", "FLIPKART", "MOCK", "LOCAL").
     */
    public Optional<ShoppingProvider> getProvider(String providerName) {
        if (providerName == null) return Optional.empty();
        return Optional.ofNullable(providerMap.get(providerName.toUpperCase().trim()));
    }

    /**
     * Get all registered providers.
     */
    public List<ShoppingProvider> getAllProviders() {
        return new ArrayList<>(providerMap.values());
    }

    /**
     * Get only currently operational and enabled providers.
     */
    public List<ShoppingProvider> getEnabledProviders() {
        return providerMap.values().stream()
                .filter(ShoppingProvider::isEnabled)
                .filter(p -> !p.getProviderName().toUpperCase().contains("MOCK") &&
                             !p.getProviderName().toUpperCase().contains("DEMO"))
                .collect(Collectors.toList());
    }

    /**
     * Check if a specific provider officially supports a given capability.
     */
    public boolean supportsCapability(String providerName, ProviderCapability capability) {
        return getProvider(providerName)
                .map(p -> p.getCapabilities().contains(capability))
                .orElse(false);
    }

    /**
     * Return the set of declared capabilities for a provider.
     */
    public Set<ProviderCapability> getCapabilities(String providerName) {
        return getProvider(providerName)
                .map(ShoppingProvider::getCapabilities)
                .orElse(Collections.emptySet());
    }
}
