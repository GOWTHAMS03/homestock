package com.homestock.modules.sync.service;

import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.sync.entity.HomeChangeLog;
import com.homestock.modules.sync.repository.HomeChangeLogRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class HomeChangeLogService {

    private static final Logger log = LoggerFactory.getLogger(HomeChangeLogService.class);

    private final HomeChangeLogRepository changeLogRepository;
    private final HomeRepository homeRepository;

    public HomeChangeLogService(HomeChangeLogRepository changeLogRepository, HomeRepository homeRepository) {
        this.changeLogRepository = changeLogRepository;
        this.homeRepository = homeRepository;
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public HomeChangeLog recordChange(
            Home home,
            String entityType,
            UUID entityId,
            String operationType,
            String payload,
            String operationId
    ) {
        // Lock the Home row to guarantee atomic monotonic sequence ordering across concurrent family edits
        homeRepository.findWithLockById(home.getId());

        Long maxVer = changeLogRepository.findMaxVersionByHomeId(home.getId());
        Long nextVersion = (maxVer != null ? maxVer : 0L) + 1L;

        HomeChangeLog changeLog = HomeChangeLog.builder()
                .home(home)
                .changeVersion(nextVersion)
                .entityType(entityType)
                .entityId(entityId)
                .operationType(operationType)
                .payload(payload)
                .operationId(operationId)
                .createdAt(Instant.now())
                .build();

        HomeChangeLog saved = changeLogRepository.save(changeLog);
        log.debug("Recorded change log for home {}: version={}, type={}, entityId={}",
                home.getId(), nextVersion, entityType, entityId);
        return saved;
    }

    @Transactional(readOnly = true)
    public Long getMaxVersion(UUID homeId) {
        Long max = changeLogRepository.findMaxVersionByHomeId(homeId);
        return max != null ? max : 0L;
    }

    @Transactional(readOnly = true)
    public List<HomeChangeLog> getChangesSince(UUID homeId, Long sinceVersion) {
        long effectiveSince = sinceVersion != null ? sinceVersion : 0L;
        return changeLogRepository.findByHomeIdAndChangeVersionGreaterThanOrderByChangeVersionAsc(
                homeId, effectiveSince);
    }

    @Transactional(readOnly = true)
    public List<HomeChangeLog> getChangesSince(UUID homeId, Long sinceVersion, int limit) {
        long effectiveSince = sinceVersion != null ? sinceVersion : 0L;
        int safeLimit = limit > 0 ? Math.min(limit, 1000) : 500;
        return changeLogRepository.findByHomeIdAndChangeVersionGreaterThan(
                homeId, effectiveSince, PageRequest.of(0, safeLimit));
    }
}
