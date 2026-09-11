package com.homestock.modules.smartshopping.engine.matching;

import com.homestock.modules.smartshopping.dto.*;
import com.homestock.modules.smartshopping.engine.filter.HardConstraintFilter;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.*;

/**
 * Product Identity Matcher:
 * Coordinates HardConstraintFilter and EvidenceScorer to evaluate candidates,
 * compute source agreement across the 6 engines, enforce Zero-Mock guarantee,
 * and collect transparent rejection traces.
 */
@Component
@RequiredArgsConstructor
public class ProductIdentityMatcher {

    private static final Logger log = LoggerFactory.getLogger(ProductIdentityMatcher.class);

    private final HardConstraintFilter hardConstraintFilter;
    private final EvidenceScorer evidenceScorer;

    @Data
    @Builder
    public static class MatchResult {
        private List<ProductCandidate> validCandidates;
        private List<RejectedCandidate> rejectedCandidates;
    }

    /**
     * Matches raw engine candidates against the resolved ProductIdentity.
     */
    public MatchResult matchCandidates(ProductIdentity identity, List<ProductCandidate> rawCandidates) {
        List<ProductCandidate> valid = new ArrayList<>();
        List<RejectedCandidate> rejected = new ArrayList<>();

        if (rawCandidates == null || rawCandidates.isEmpty()) {
            return MatchResult.builder()
                    .validCandidates(valid)
                    .rejectedCandidates(rejected)
                    .build();
        }

        // 1. Calculate provider consensus / agreement per normalized title
        Map<String, Set<String>> titleToProviders = new HashMap<>();
        for (ProductCandidate cand : rawCandidates) {
            if (cand == null || cand.getProductName() == null) continue;
            String key = cand.getProductName().trim().toLowerCase();
            String prov = cand.getProvider() != null ? cand.getProvider() : "unknown";
            titleToProviders.computeIfAbsent(key, k -> new HashSet<>()).add(prov);
        }

        // 2. Evaluate each candidate
        for (ProductCandidate cand : rawCandidates) {
            // A. Hard Constraint Pre-Filtering
            HardConstraintFilter.FilterResult filterRes = hardConstraintFilter.evaluate(identity, cand);
            if (!filterRes.passed()) {
                rejected.add(filterRes.rejection());
                cand.setRejectionReason(filterRes.rejection().getRejectionReason());
                continue;
            }

            // B. Determine source consensus agreement count
            String key = cand.getProductName().trim().toLowerCase();
            int sourceAgreement = titleToProviders.getOrDefault(key, Set.of("unknown")).size();
            cand.setSourceAgreementCount(sourceAgreement);

            // C. Multi-signal Evidence Scoring
            EvidenceScorer.ScoredEvidence scored = evidenceScorer.score(identity, cand, sourceAgreement);

            if (scored.status() == MatchStatus.REJECT || scored.confidence() < 0.60) {
                RejectedCandidate rej = RejectedCandidate.builder()
                        .candidateTitle(cand.getProductName())
                        .provider(cand.getProvider())
                        .rejectionReason(RejectionReason.LOW_CONFIDENCE)
                        .details("Evidence score " + String.format("%.1f%%", scored.confidence() * 100) + " below minimum match threshold")
                        .build();
                rejected.add(rej);
                cand.setRejectionReason(RejectionReason.LOW_CONFIDENCE);
                continue;
            }

            // D. Attach evidence and score to candidate
            cand.setScore(scored.confidence() * 100.0);
            cand.setMatchStatus(scored.status());
            cand.setEvidence(scored.evidence());
            cand.setCanonicalBrand(identity.getBrand());
            cand.setCanonicalProduct(identity.getProduct());
            cand.setNormalizedPackSizeValue(identity.getNormalizedPackSizeValue());
            cand.setNormalizedPackSizeUnit(identity.getNormalizedPackSizeUnit());

            valid.add(cand);
        }

        log.info("Matching completed: {} raw candidates -> {} valid candidates, {} rejected",
                rawCandidates.size(), valid.size(), rejected.size());

        return MatchResult.builder()
                .validCandidates(valid)
                .rejectedCandidates(rejected)
                .build();
    }
}
