package com.homestock.modules.notification.service;

import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.entity.HomeMember;
import com.homestock.modules.home.repository.HomeMemberRepository;
import com.homestock.modules.notification.entity.Notification;
import com.homestock.modules.notification.entity.NotificationType;
import com.homestock.modules.notification.repository.NotificationRepository;
import com.homestock.modules.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final NotificationRepository notificationRepository;
    private final HomeMemberRepository homeMemberRepository;

    @Transactional
    public void notifyHomeMembers(Home home, User excludedUser, NotificationType type, String title, String body, String payloadJson) {
        List<HomeMember> members = homeMemberRepository.findAllByHomeId(home.getId());

        for (HomeMember member : members) {
            User targetUser = member.getUser();
            if (excludedUser != null && targetUser.getId().equals(excludedUser.getId())) {
                continue; // Do not notify the member who initiated the action
            }

            Notification notification = Notification.builder()
                    .home(home)
                    .user(targetUser)
                    .type(type)
                    .title(title)
                    .body(body)
                    .payloadJson(payloadJson)
                    .isRead(false)
                    .build();

            notificationRepository.save(notification);
            log.info("Dispatched {} notification to user {}: {}", type, targetUser.getEmail(), title);
        }
    }

    @Transactional
    public void notifyUser(Home home, User user, NotificationType type, String title, String body, String payloadJson) {
        Notification notification = Notification.builder()
                .home(home)
                .user(user)
                .type(type)
                .title(title)
                .body(body)
                .payloadJson(payloadJson)
                .isRead(false)
                .build();
        notificationRepository.save(notification);
    }
}
