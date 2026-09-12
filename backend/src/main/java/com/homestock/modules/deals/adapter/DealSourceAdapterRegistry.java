package com.homestock.modules.deals.adapter;

import com.homestock.modules.deals.model.DealSource;
import com.homestock.modules.deals.model.ExternalProduct;
import com.homestock.modules.smartshopping.provider.ProductSearchRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.concurrent.*;

/**
 * DealSourceAdapterRegistry:
 * Manages all registered DealSourceAdapter implementations.
 * Handles parallel multi-adapter dispatch, timeout enforcement, failure tracking, and circuit breaker behavior.
 * Phase 24 — Failure Handling & Phase 28 — Performance.
 */
@Component
public class DealSourceAdapterRegistry {

    private static final Logger log = LoggerFactory.getLogger(DealSourceAdapterRegistry.class);

    private final List<DealSourceAdapter> adapters;
    private final ExecutorService executorService = Executors.newFixedThreadPool(8);

    @Value("${deals.adapter.timeout-ms:3000}")
    private long adapterTimeoutMs = 3000;

    // Track adapter failure counts for circuit breaking
    private final Map<DealSource, Integer> failureCounters = new ConcurrentHashMap<>();
    private static final int MAX_CONSECUTIVE_FAILURES = 5;

    public DealSourceAdapterRegistry(List<DealSourceAdapter> adapters) {
        this.adapters = adapters != null ? adapters : Collections.emptyList();
    }

    public List<DealSourceAdapter> getActiveAdapters() {
        List<DealSourceAdapter> active = new ArrayList<>();
        for (DealSourceAdapter a : adapters) {
            if (a.isEnabled() && !isCircuitOpen(a.getSource())) {
                active.add(a);
            }
        }
        return active;
    }

    public Optional<DealSourceAdapter> getAdapter(DealSource source) {
        return adapters.stream()
                .filter(a -> a.getSource() == source)
                .findFirst();
    }

    /**
     * Dispatch search across all enabled adapters in parallel with per-adapter timeout.
     * One adapter failing does not block or fail the others.
     */
    public List<ExternalProduct> searchAll(ProductSearchRequest request) {
        List<DealSourceAdapter> active = getActiveAdapters();
        if (active.isEmpty()) {
            log.warn("[DealSourceAdapterRegistry] No active deal source adapters found");
            return Collections.emptyList();
        }

        List<CompletableFuture<List<ExternalProduct>>> futures = new ArrayList<>();
        for (DealSourceAdapter adapter : active) {
            CompletableFuture<List<ExternalProduct>> future = CompletableFuture.supplyAsync(() -> {
                long start = System.currentTimeMillis();
                try {
                    List<ExternalProduct> res = adapter.searchProducts(request);
                    recordSuccess(adapter.getSource());
                    log.debug("[DEAL_SEARCH] source={} latency={}ms results={}",
                            adapter.getSource(), (System.currentTimeMillis() - start), res.size());
                    return res;
                } catch (Exception e) {
                    recordFailure(adapter.getSource());
                    log.warn("[DEAL_SEARCH_FAILURE] source={} error={}", adapter.getSource(), e.getMessage());
                    return Collections.<ExternalProduct>emptyList();
                }
            }, executorService).completeOnTimeout(Collections.<ExternalProduct>emptyList(), adapterTimeoutMs, TimeUnit.MILLISECONDS);

            futures.add(future);
        }

        List<ExternalProduct> aggregated = new ArrayList<>();
        for (CompletableFuture<List<ExternalProduct>> f : futures) {
            try {
                aggregated.addAll(f.join());
            } catch (Exception e) {
                log.warn("[DealSourceAdapterRegistry] Adapter aggregation warning: {}", e.getMessage());
            }
        }

        return aggregated;
    }

    private boolean isCircuitOpen(DealSource source) {
        int failures = failureCounters.getOrDefault(source, 0);
        return failures >= MAX_CONSECUTIVE_FAILURES;
    }

    private void recordFailure(DealSource source) {
        failureCounters.merge(source, 1, Integer::sum);
        if (failureCounters.get(source) >= MAX_CONSECUTIVE_FAILURES) {
            log.warn("[CIRCUIT_BREAKER] Circuit opened for source={} after {} consecutive failures",
                    source, failureCounters.get(source));
        }
    }

    private void recordSuccess(DealSource source) {
        failureCounters.put(source, 0);
    }
}
