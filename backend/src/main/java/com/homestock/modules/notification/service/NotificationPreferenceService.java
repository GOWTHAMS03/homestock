package com.homestock.modules.notification.service;

import com.homestock.modules.notification.dto.NotificationPreferenceDto;
import com.homestock.modules.notification.entity.NotificationPreference;
import com.homestock.modules.notification.repository.NotificationPreferenceRepository;
import com.homestock.modules.user.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalTime;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationPreferenceService {

    private final NotificationPreferenceRepository preferenceRepository;

    @Transactional
    public NotificationPreference getOrCreatePreferences(User user) {
        return preferenceRepository.findByUserId(user.getId())
                .orElseGet(() -> {
                    NotificationPreference defaultPref = NotificationPreference.builder()
                            .user(user)
                            .lowStockEnabled(true)
                            .outOfStockEnabled(true)
                            .expiryEnabled(true)
                            .shoppingListEnabled(true)
                            .familyActivityEnabled(true)
                            .purchaseEnabled(true)
                            .smartSuggestionEnabled(true)
                            .weeklyInsightEnabled(true)
                            .monthlyReportEnabled(true)
                            .quietHoursEnabled(true)
                            .quietHoursStart(LocalTime.of(22, 0))
                            .quietHoursEnd(LocalTime.of(7, 0))
                            .build();
                    return preferenceRepository.save(defaultPref);
                });
    }

    @Transactional(readOnly = true)
    public NotificationPreference getPreferencesForUser(UUID userId) {
        return preferenceRepository.findByUserId(userId).orElse(null);
    }

    @Transactional
    public NotificationPreferenceDto updatePreferences(User user, NotificationPreferenceDto dto) {
        NotificationPreference pref = getOrCreatePreferences(user);

        if (dto.getLowStockEnabled() != null) pref.setLowStockEnabled(dto.getLowStockEnabled());
        if (dto.getOutOfStockEnabled() != null) pref.setOutOfStockEnabled(dto.getOutOfStockEnabled());
        if (dto.getExpiryEnabled() != null) pref.setExpiryEnabled(dto.getExpiryEnabled());
        if (dto.getShoppingListEnabled() != null) pref.setShoppingListEnabled(dto.getShoppingListEnabled());
        if (dto.getFamilyActivityEnabled() != null) pref.setFamilyActivityEnabled(dto.getFamilyActivityEnabled());
        if (dto.getPurchaseEnabled() != null) pref.setPurchaseEnabled(dto.getPurchaseEnabled());
        if (dto.getSmartSuggestionEnabled() != null) pref.setSmartSuggestionEnabled(dto.getSmartSuggestionEnabled());
        if (dto.getWeeklyInsightEnabled() != null) pref.setWeeklyInsightEnabled(dto.getWeeklyInsightEnabled());
        if (dto.getMonthlyReportEnabled() != null) pref.setMonthlyReportEnabled(dto.getMonthlyReportEnabled());
        if (dto.getQuietHoursEnabled() != null) pref.setQuietHoursEnabled(dto.getQuietHoursEnabled());
        if (dto.getQuietHoursStart() != null) pref.setQuietHoursStart(dto.getQuietHoursStart());
        if (dto.getQuietHoursEnd() != null) pref.setQuietHoursEnd(dto.getQuietHoursEnd());

        NotificationPreference saved = preferenceRepository.save(pref);
        log.info("Updated notification preferences for user {}", user.getId());
        return NotificationPreferenceDto.fromEntity(saved);
    }
}

