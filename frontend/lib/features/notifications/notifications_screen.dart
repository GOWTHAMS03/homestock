import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/homestock/homestock_card.dart';
import '../../core/router/notification_router.dart';
import '../home_switcher/home_controller.dart';
import 'notification_controller.dart';
import 'notification_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'ALL'; // 'ALL', 'UNREAD'

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(notificationControllerProvider);
    final allNotifications = notifState.notifications;

    final filtered = _selectedFilter == 'UNREAD'
        ? allNotifications.where((n) => !n.isRead).toList()
        : allNotifications;

    // Group by Today vs Earlier
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayNotifications = <NotificationModel>[];
    final earlierNotifications = <NotificationModel>[];

    for (final n in filtered) {
      final date = DateTime.tryParse(n.createdAt) ?? now;
      final itemDay = DateTime(date.year, date.month, date.day);
      if (itemDay.isAtSameMomentAs(today) || itemDay.isAfter(today)) {
        todayNotifications.add(n);
      } else {
        earlierNotifications.add(n);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: HomeStockAppBar(
        title: 'Notifications',
        subtitle: '${notifState.unreadCount} unread alert(s)',
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            tooltip: 'Notification Preferences',
            onPressed: () => context.push('/settings/notifications'),
          ),
          if (notifState.unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationControllerProvider.notifier).markAllAsRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          _buildFilterChips(notifState),

          // Notification List
          Expanded(
            child: notifState.isLoading && allNotifications.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? RefreshIndicator(
                        onRefresh: () => _handleRefresh(ref),
                        child: ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            EmptyStateView(
                              icon: Icons.notifications_none_rounded,
                              title: _selectedFilter == 'UNREAD' ? 'No unread alerts' : 'No notifications',
                              message: _selectedFilter == 'UNREAD'
                                  ? 'You are all caught up!'
                                  : 'Low stock alerts, expiry reminders, and updates will appear here.',
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _handleRefresh(ref),
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
                          children: [
                            if (todayNotifications.isNotEmpty) ...[
                              _buildSectionTitle('TODAY'),
                              ...todayNotifications.map((n) => _buildNotificationCard(n)),
                            ],
                            if (earlierNotifications.isNotEmpty) ...[
                              if (todayNotifications.isNotEmpty) const SizedBox(height: 16),
                              _buildSectionTitle('EARLIER'),
                              ...earlierNotifications.map((n) => _buildNotificationCard(n)),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRefresh(WidgetRef ref) async {
    final activeHome = ref.read(homeControllerProvider).activeHome;
    if (activeHome != null) {
      await ref.read(notificationControllerProvider.notifier).runLocalScan(activeHome.id);
    } else {
      await ref.read(notificationControllerProvider.notifier).loadNotifications();
    }
  }

  Widget _buildFilterChips(NotificationState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: Text('All (${state.notifications.length})'),
            selected: _selectedFilter == 'ALL',
            selectedColor: AppColors.primaryContainer,
            labelStyle: TextStyle(
              color: _selectedFilter == 'ALL' ? AppColors.primary : AppColors.textSecondary,
              fontWeight: _selectedFilter == 'ALL' ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
            onSelected: (_) => setState(() => _selectedFilter = 'ALL'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('Unread (${state.unreadCount})'),
            selected: _selectedFilter == 'UNREAD',
            selectedColor: AppColors.primaryContainer,
            labelStyle: TextStyle(
              color: _selectedFilter == 'UNREAD' ? AppColors.primary : AppColors.textSecondary,
              fontWeight: _selectedFilter == 'UNREAD' ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
            onSelected: (_) => setState(() => _selectedFilter = 'UNREAD'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    final styling = _getNotificationStyling(notif.type);
    final date = DateTime.tryParse(notif.createdAt) ?? DateTime.now();
    final dateStr = DateFormat('dd MMM, hh:mm a').format(date);

    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(notificationControllerProvider.notifier).deleteNotification(notif.id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: HomeStockCard(
          backgroundColor: notif.isRead ? Colors.white : const Color(0xFFFAF5FF),
          borderColor: notif.isRead
              ? AppColors.outline.withValues(alpha: 0.6)
              : AppColors.primary.withValues(alpha: 0.35),
          padding: const EdgeInsets.all(14),
          onTap: () {
            if (!notif.isRead) {
              ref.read(notificationControllerProvider.notifier).markAsRead(notif.id);
            }
            _handleNotificationTap(notif);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: styling.bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(styling.icon, size: 20, color: styling.iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (!notif.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          notif.body,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              dateStr,
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                            if (notif.priority == 'HIGH') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Text(
                                  'HIGH',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Action Buttons
              _buildCardActions(notif),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardActions(NotificationModel notif) {
    final actions = <Widget>[];

    // Out of stock / Low stock / Smart restock
    if (notif.type == 'OUT_OF_STOCK' ||
        notif.type == 'LOW_STOCK' ||
        notif.type == 'SMART_RESTOCK_SUGGESTION') {
      actions.add(
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.add_shopping_cart, size: 14, color: AppColors.primary),
          label: const Text('Go to Shopping', style: TextStyle(fontSize: 11, color: AppColors.primary)),
          onPressed: () {
            if (!notif.isRead) {
              ref.read(notificationControllerProvider.notifier).markAsRead(notif.id);
            }
            context.push('/shopping');
          },
        ),
      );

      if (notif.targetItemId != null && notif.targetItemId!.isNotEmpty) {
        actions.add(const SizedBox(width: 8));
        actions.add(
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            ),
            child: const Text('View Item', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            onPressed: () {
              if (!notif.isRead) {
                ref.read(notificationControllerProvider.notifier).markAsRead(notif.id);
              }
              context.push('/inventory/detail/${notif.targetItemId}');
            },
          ),
        );
      }
    } else if (notif.type == 'EXPIRY_REMINDER' && notif.targetItemId != null) {
      actions.add(
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            side: BorderSide(color: Colors.amber.shade600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: Icon(Icons.visibility_outlined, size: 14, color: Colors.amber.shade800),
          label: Text('Inspect Item', style: TextStyle(fontSize: 11, color: Colors.amber.shade900)),
          onPressed: () {
            if (!notif.isRead) {
              ref.read(notificationControllerProvider.notifier).markAsRead(notif.id);
            }
            context.push('/inventory/detail/${notif.targetItemId}');
          },
        ),
      );
    } else if (notif.type == 'WEEKLY_INSIGHT' || notif.type == 'MONTHLY_REPORT') {
      actions.add(
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.insights, size: 14, color: AppColors.primary),
          label: const Text('View Insights', style: TextStyle(fontSize: 11, color: AppColors.primary)),
          onPressed: () {
            if (!notif.isRead) {
              ref.read(notificationControllerProvider.notifier).markAsRead(notif.id);
            }
            context.push('/analytics');
          },
        ),
      );
    } else if (notif.type == 'SHOPPING_LIST_UPDATE') {
      actions.add(
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.primary),
          label: const Text('View List', style: TextStyle(fontSize: 11, color: AppColors.primary)),
          onPressed: () {
            if (!notif.isRead) {
              ref.read(notificationControllerProvider.notifier).markAsRead(notif.id);
            }
            context.push('/shopping');
          },
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 44),
      child: Row(children: actions),
    );
  }

  void _handleNotificationTap(NotificationModel notif) {
    NotificationRouter(ref).routeNotificationModel(
      context: context,
      notif: notif,
    );
  }

  _NotificationStyling _getNotificationStyling(String type) {
    switch (type) {
      case 'OUT_OF_STOCK':
        return _NotificationStyling(
          icon: Icons.cancel_outlined,
          iconColor: AppColors.outOfStockText,
          bgColor: AppColors.outOfStockBg,
        );
      case 'LOW_STOCK':
        return _NotificationStyling(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.lowStockText,
          bgColor: AppColors.lowStockBg,
        );
      case 'EXPIRY_REMINDER':
      case 'EXPIRING_SOON':
      case 'EXPIRED':
        return _NotificationStyling(
          icon: Icons.access_time_rounded,
          iconColor: AppColors.expiringSoonText,
          bgColor: AppColors.expiringSoonBg,
        );
      case 'SHOPPING_LIST_UPDATE':
        return _NotificationStyling(
          icon: Icons.shopping_bag_outlined,
          iconColor: AppColors.primary,
          bgColor: AppColors.primaryContainer,
        );
      case 'FAMILY_ACTIVITY':
        return _NotificationStyling(
          icon: Icons.people_outline_rounded,
          iconColor: Colors.teal.shade700,
          bgColor: Colors.teal.shade50,
        );
      case 'PURCHASE_RECORDED':
        return _NotificationStyling(
          icon: Icons.receipt_long_outlined,
          iconColor: Colors.green.shade700,
          bgColor: Colors.green.shade50,
        );
      case 'STOCK_UPDATED':
        return _NotificationStyling(
          icon: Icons.sync_alt_rounded,
          iconColor: Colors.indigo.shade700,
          bgColor: Colors.indigo.shade50,
        );
      case 'SMART_RESTOCK_SUGGESTION':
        return _NotificationStyling(
          icon: Icons.lightbulb_outline_rounded,
          iconColor: Colors.deepOrange.shade700,
          bgColor: Colors.deepOrange.shade50,
        );
      case 'WEEKLY_INSIGHT':
        return _NotificationStyling(
          icon: Icons.auto_awesome_outlined,
          iconColor: Colors.purple.shade700,
          bgColor: Colors.purple.shade50,
        );
      case 'MONTHLY_REPORT':
        return _NotificationStyling(
          icon: Icons.bar_chart_rounded,
          iconColor: Colors.blue.shade700,
          bgColor: Colors.blue.shade50,
        );
      case 'SYNC_COMPLETED':
        return _NotificationStyling(
          icon: Icons.cloud_done_outlined,
          iconColor: Colors.green.shade700,
          bgColor: Colors.green.shade50,
        );
      default:
        return _NotificationStyling(
          icon: Icons.info_outline_rounded,
          iconColor: AppColors.primary,
          bgColor: AppColors.surfaceVariant,
        );
    }
  }
}

class _NotificationStyling {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  _NotificationStyling({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}
