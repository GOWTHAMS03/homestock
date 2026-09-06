package com.homestock.modules.inventory.scheduler;

import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.notification.entity.NotificationType;
import com.homestock.modules.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Component
@RequiredArgsConstructor
public class ExpiryAlertScheduler {

    private static final Logger log = LoggerFactory.getLogger(ExpiryAlertScheduler.class);

    private final HomeRepository homeRepository;
    private final InventoryItemRepository inventoryItemRepository;
    private final NotificationService notificationService;

    // Run every day at 8:00 AM (server time)
    @Scheduled(cron = "${app.scheduler.expiry-cron:0 0 8 * * *}")
    @Transactional
    public void checkExpiringItemsAndNotify() {
        log.info("Starting daily household expiry check...");
        LocalDate today = LocalDate.now();
        LocalDate in3Days = today.plusDays(3);

        List<Home> homes = homeRepository.findAll();
        for (Home home : homes) {
            List<InventoryItem> expiringItems = inventoryItemRepository.findExpiringSoonItems(home.getId(), today, in3Days);

            for (InventoryItem item : expiringItems) {
                long days = item.getDaysUntilExpiry() != null ? item.getDaysUntilExpiry() : 0;
                String timeStr = days == 0 ? "today" : (days == 1 ? "tomorrow" : "in " + days + " days");

                notificationService.notifyHomeMembers(
                        home,
                        null,
                        NotificationType.EXPIRING_SOON,
                        item.getName() + " expires " + timeStr,
                        "Your " + item.getName() + " in " + (item.getStorageLocation() != null ? item.getStorageLocation() : "inventory") + " expires " + timeStr + ". Consider using it soon!",
                        "{\"itemId\":\"" + item.getId() + "\"}"
                );
            }
        }
        log.info("Daily expiry check completed.");
    }
}
