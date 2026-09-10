package com.homestock.modules.notification.scheduler;

import com.homestock.modules.consumption.entity.ConsumptionProfile;
import com.homestock.modules.consumption.repository.ConsumptionProfileRepository;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.notification.repository.NotificationDeduplicationRepository;
import com.homestock.modules.notification.repository.NotificationRepository;
import com.homestock.modules.notification.service.NotificationEngine;
import com.homestock.modules.purchase.repository.PurchaseItemRepository;
import com.homestock.modules.purchase.repository.PurchaseRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class NotificationScheduler {

    private final HomeRepository homeRepository;
    private final InventoryItemRepository inventoryItemRepository;
    private final ConsumptionProfileRepository consumptionProfileRepository;
    private final PurchaseRepository purchaseRepository;
    private final PurchaseItemRepository purchaseItemRepository;
    private final NotificationRepository notificationRepository;
    private final NotificationDeduplicationRepository deduplicationRepository;
    private final NotificationEngine notificationEngine;

    @Value("${app.notifications.retention-days:90}")
    private int retentionDays = 90;

    /**
     * Daily Expiry Check at 8:00 AM.
     * Evaluates items expiring in 3 days, tomorrow, today, or already expired.
     */
    @Scheduled(cron = "${app.scheduler.expiry-cron:0 0 8 * * *}")
    @Transactional
    public void runDailyExpiryCheck() {
        log.info("[NotificationScheduler] Starting daily household expiry evaluation...");
        LocalDate today = LocalDate.now();
        LocalDate in3Days = today.plusDays(3);

        List<Home> homes = homeRepository.findAll();
        for (Home home : homes) {
            List<InventoryItem> expiringItems = inventoryItemRepository.findExpiringSoonItems(home.getId(), today.minusDays(1), in3Days);

            for (InventoryItem item : expiringItems) {
                if (item.getExpiryDate() == null) continue;
                long days = ChronoUnit.DAYS.between(today, item.getExpiryDate());
                notificationEngine.notifyExpiry(home, item, days);
            }
        }
        log.info("[NotificationScheduler] Daily expiry evaluation completed.");
    }

    /**
     * Daily Smart Restock Check at 8:30 AM.
     * Uses deterministic average purchase intervals to remind users.
     */
    @Scheduled(cron = "${app.scheduler.restock-cron:0 30 8 * * *}")
    @Transactional
    public void runDailySmartRestockCheck() {
        log.info("[NotificationScheduler] Starting daily smart restock evaluation...");
        List<Home> homes = homeRepository.findAll();
        LocalDate today = LocalDate.now();

        for (Home home : homes) {
            List<ConsumptionProfile> profiles = consumptionProfileRepository.findAllByHomeId(home.getId());
            for (ConsumptionProfile profile : profiles) {
                if (profile.getInventoryItem() == null || profile.getLastPurchaseDate() == null) continue;
                BigDecimal interval = profile.getAveragePurchaseInterval();
                if (interval == null || interval.compareTo(BigDecimal.valueOf(2)) <= 0) continue;

                long daysSince = ChronoUnit.DAYS.between(profile.getLastPurchaseDate(), today);
                long expectedInterval = interval.longValue();

                // If days since last purchase is around the average purchase interval
                if (daysSince >= expectedInterval - 1 && daysSince <= expectedInterval + 2) {
                    InventoryItem item = profile.getInventoryItem();
                    notificationEngine.notifySmartRestock(
                            home, item, "You usually buy " + item.getName() + " every ~" + expectedInterval + " days."
                    );
                }
            }
        }
        log.info("[NotificationScheduler] Daily smart restock evaluation completed.");
    }

    /**
     * Weekly Insight generation every Monday at 9:00 AM.
     */
    @Scheduled(cron = "${app.scheduler.weekly-insight-cron:0 0 9 * * MON}")
    @Transactional
    public void runWeeklyInsightCheck() {
        log.info("[NotificationScheduler] Generating weekly insights for households...");
        LocalDate startOfWeek = LocalDate.now().minusDays(7);
        List<Home> homes = homeRepository.findAll();

        for (Home home : homes) {
            BigDecimal weeklySpend = purchaseRepository.calculateTotalSpendingSince(home.getId(), startOfWeek);
            List<Object[]> topItems = purchaseItemRepository.getMostPurchasedItems(home.getId());
            String topItemName = null;
            if (!topItems.isEmpty() && topItems.getFirst()[0] != null) {
                topItemName = (String) topItems.getFirst()[0];
            }

            List<InventoryItem> expiring = inventoryItemRepository.findExpiringSoonItems(
                    home.getId(), LocalDate.now(), LocalDate.now().plusDays(7)
            );

            notificationEngine.notifyWeeklyInsight(home, weeklySpend, topItemName, expiring.size());
        }
        log.info("[NotificationScheduler] Weekly insights completed.");
    }

    /**
     * Monthly Report generation on the 1st of every month at 9:00 AM.
     */
    @Scheduled(cron = "${app.scheduler.monthly-report-cron:0 0 9 1 * *}")
    @Transactional
    public void runMonthlyReportCheck() {
        log.info("[NotificationScheduler] Generating monthly reports for households...");
        LocalDate startOfMonth = LocalDate.now().minusMonths(1).withDayOfMonth(1);
        List<Home> homes = homeRepository.findAll();

        for (Home home : homes) {
            BigDecimal monthlySpend = purchaseRepository.calculateTotalSpendingSince(home.getId(), startOfMonth);
            int purchasesCount = purchaseRepository.countPurchasesSince(home.getId(), startOfMonth);
            notificationEngine.notifyMonthlyReport(home, monthlySpend, purchasesCount);
        }
        log.info("[NotificationScheduler] Monthly reports completed.");
    }

    /**
     * Daily notification cleanup at 3:00 AM.
     * Deletes read notifications older than retention days (default 90 days).
     */
    @Scheduled(cron = "${app.scheduler.cleanup-cron:0 0 3 * * *}")
    @Transactional
    public void runNotificationCleanup() {
        log.info("[NotificationScheduler] Running retention cleanup for notifications older than {} days...", retentionDays);
        Instant cutoff = Instant.now().minus(retentionDays, ChronoUnit.DAYS);
        int deletedNotifs = notificationRepository.deleteReadOlderThan(cutoff);
        int deletedDedups = deduplicationRepository.deleteOlderThan(Instant.now().minus(30, ChronoUnit.DAYS));
        log.info("[NotificationScheduler] Cleanup finished: {} read notification(s) and {} deduplication record(s) removed.",
                deletedNotifs, deletedDedups);
    }
}

