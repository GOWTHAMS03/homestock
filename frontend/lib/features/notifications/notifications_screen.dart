import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/empty_state_view.dart';
import 'notification_controller.dart';
import 'notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationControllerProvider);
    final notifications = notifState.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifState.unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationControllerProvider.notifier).markAllAsRead(),
              child: const Text('Mark all read', style: TextStyle(fontSize: 13, color: AppColors.primary)),
            ),
        ],
      ),
      body: notifState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const EmptyStateView(
                  icon: Icons.notifications_none_rounded,
                  title: 'No notifications',
                  message: 'You are up to date! Low stock alerts and expiry reminders will appear here.',
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(notificationControllerProvider.notifier).loadNotifications(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return _buildNotificationCard(context, ref, n);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, WidgetRef ref, NotificationModel notif) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (notif.type) {
      case 'OUT_OF_STOCK':
        icon = Icons.cancel_outlined;
        iconColor = AppColors.outOfStockText;
        bgColor = AppColors.outOfStockBg;
        break;
      case 'LOW_STOCK':
        icon = Icons.warning_amber_rounded;
        iconColor = AppColors.lowStockText;
        bgColor = AppColors.lowStockBg;
        break;
      case 'EXPIRING_SOON':
      case 'EXPIRED':
        icon = Icons.access_time_rounded;
        iconColor = AppColors.expiringSoonText;
        bgColor = AppColors.expiringSoonBg;
        break;
      case 'SHOPPING_LIST_UPDATE':
        icon = Icons.shopping_bag_outlined;
        iconColor = AppColors.primary;
        bgColor = AppColors.primaryContainer;
        break;
      default:
        icon = Icons.info_outline_rounded;
        iconColor = AppColors.primary;
        bgColor = AppColors.surfaceVariant;
    }

    final dateStr = DateFormat('dd MMM, hh:mm a').format(DateTime.tryParse(notif.createdAt) ?? DateTime.now());

    return Card(
      color: notif.isRead ? AppColors.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: notif.isRead ? AppColors.outline : AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () {
          if (!notif.isRead) {
            ref.read(notificationControllerProvider.notifier).markAsRead(notif.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
