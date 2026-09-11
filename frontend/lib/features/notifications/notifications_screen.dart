import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/router/notification_router.dart';
import '../home_switcher/home_controller.dart';
import '../shopping/shopping_controller.dart';
import 'notification_controller.dart';
import 'notification_model.dart';

/// Redesigned HomeStock Notifications Screen
/// Built with the exact same visual identity & senior-level UX psychology as the Home screen:
/// - Rounded 20 cards with pastel semantic badges & soft elevation
/// - Quick Summary & Action Card with "Mark all read" and "Clear all"
/// - Horizontal category filter pills (All, Unread, Stock, Expiry, Shopping)
/// - Seamless Deletion UX: Swipe-to-delete with Undo SnackBar, direct delete button on cards, and Clear All confirmation sheet
/// - Problem-matched CTAs right on the notification cards (+ Add to Shopping List, Inspect Item, View List)
/// - Date grouping: "TODAY", "YESTERDAY", "EARLIER" with friendly relative timestamps
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'ALL'; // 'ALL', 'UNREAD', 'STOCK', 'EXPIRY', 'SHOPPING'

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(notificationControllerProvider);
    final allNotifications = notifState.notifications;

    // Filter notifications based on selected pill
    final filtered = _filterNotifications(allNotifications, _selectedFilter);

    // Group by Today, Yesterday, and Earlier
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayNotifications = <NotificationModel>[];
    final yesterdayNotifications = <NotificationModel>[];
    final earlierNotifications = <NotificationModel>[];

    for (final n in filtered) {
      final date = DateTime.tryParse(n.createdAt)?.toLocal() ?? now;
      final itemDay = DateTime(date.year, date.month, date.day);
      if (itemDay.isAtSameMomentAs(today) || itemDay.isAfter(today)) {
        todayNotifications.add(n);
      } else if (itemDay.isAtSameMomentAs(yesterday)) {
        yesterdayNotifications.add(n);
      } else {
        earlierNotifications.add(n);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP HEADER (Back button, Title, Unread Pill Badge & Preferences icon)
            _buildHeader(context, ref, notifState.unreadCount, allNotifications.length),

            // 2. SUMMARY & QUICK ACTIONS CARD (When notifications exist)
            if (allNotifications.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _buildSummaryCard(context, ref, notifState.unreadCount, allNotifications.length),
              ),

            const SizedBox(height: 10),

            // 3. HORIZONTAL CATEGORY FILTER PILLS
            _buildFilterPills(allNotifications, notifState.unreadCount),

            const SizedBox(height: 10),

            // 4. NOTIFICATION LIST OR CALM EMPTY STATE
            Expanded(
              child: notifState.isLoading && allNotifications.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                    )
                  : filtered.isEmpty
                      ? RefreshIndicator(
                          color: const Color(0xFF6366F1),
                          onRefresh: () => _handleRefresh(ref),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                              _buildEmptyState(context),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF6366F1),
                          onRefresh: () => _handleRefresh(ref),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 4, AppSpacing.lg, 24),
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            children: [
                              // Group: TODAY
                              if (todayNotifications.isNotEmpty) ...[
                                _buildDateSectionHeader('TODAY'),
                                ...todayNotifications.map((n) => _buildNotificationCard(n)),
                              ],

                              // Group: YESTERDAY
                              if (yesterdayNotifications.isNotEmpty) ...[
                                if (todayNotifications.isNotEmpty) const SizedBox(height: 14),
                                _buildDateSectionHeader('YESTERDAY'),
                                ...yesterdayNotifications.map((n) => _buildNotificationCard(n)),
                              ],

                              // Group: EARLIER
                              if (earlierNotifications.isNotEmpty) ...[
                                if (todayNotifications.isNotEmpty || yesterdayNotifications.isNotEmpty)
                                  const SizedBox(height: 14),
                                _buildDateSectionHeader('EARLIER'),
                                ...earlierNotifications.map((n) => _buildNotificationCard(n)),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // 1. TOP HEADER
  // ==================================================
  Widget _buildHeader(BuildContext context, WidgetRef ref, int unreadCount, int totalCount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button & Title with Unread Pill
          Row(
            children: [
              InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dynamic unread pill badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: unreadCount > 0 ? const Color(0xFFEDE9FE) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: unreadCount > 0 ? const Color(0xFFDDD6FE) : const Color(0xFFBBF7D0),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          unreadCount > 0 ? '$unreadCount new' : 'All caught up ✓',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: unreadCount > 0 ? const Color(0xFF6D28D9) : const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Actions on the right: Settings & Clear All Options
          Row(
            children: [
              // Notification Preferences Shortcut
              InkWell(
                onTap: () => context.push('/settings/notifications'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDD6FE), width: 1.0),
                  ),
                  child: const Icon(Icons.tune_rounded, size: 19, color: Color(0xFF6366F1)),
                ),
              ),
              if (totalCount > 0) ...[
                const SizedBox(width: 8),
                // Overflow menu for Clear All
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  icon: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                    ),
                    child: const Icon(Icons.more_horiz_rounded, size: 20, color: Color(0xFF64748B)),
                  ),
                  onSelected: (val) {
                    if (val == 'READ_ALL') {
                      ref.read(notificationControllerProvider.notifier).markAllAsRead();
                    } else if (val == 'CLEAR_ALL') {
                      _showClearAllConfirmation(context, ref);
                    }
                  },
                  itemBuilder: (context) => [
                    if (unreadCount > 0)
                      const PopupMenuItem(
                        value: 'READ_ALL',
                        child: Row(
                          children: [
                            Icon(Icons.done_all_rounded, size: 18, color: Color(0xFF6366F1)),
                            SizedBox(width: 10),
                            Text('Mark all as read', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'CLEAR_ALL',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_outlined, size: 18, color: Color(0xFFDC2626)),
                          SizedBox(width: 10),
                          Text('Clear all notifications', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ==================================================
  // 2. SUMMARY & QUICK ACTION CARD
  // ==================================================
  Widget _buildSummaryCard(BuildContext context, WidgetRef ref, int unreadCount, int totalCount) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Alerts overview
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.notifications_active_rounded, size: 18, color: Color(0xFF6366F1)),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alerts Center',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '$totalCount total • $unreadCount unread',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (unreadCount > 0)
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(notificationControllerProvider.notifier).markAllAsRead();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDD6FE), width: 1.0),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_rounded, size: 14, color: Color(0xFF6D28D9)),
                        SizedBox(width: 4),
                        Text(
                          'Mark read',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6D28D9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              // Clear button
              InkWell(
                onTap: () => _showClearAllConfirmation(context, ref),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFEE2E2), width: 1.0),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, size: 14, color: Color(0xFFDC2626)),
                      SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================================================
  // 3. HORIZONTAL FILTER PILLS
  // ==================================================
  Widget _buildFilterPills(List<NotificationModel> allNotifications, int unreadCount) {
    final stockCount = allNotifications.where((n) => n.type == 'OUT_OF_STOCK' || n.type == 'LOW_STOCK' || n.type == 'SMART_RESTOCK_SUGGESTION').length;
    final expiryCount = allNotifications.where((n) => n.type == 'EXPIRY_REMINDER' || n.type == 'EXPIRING_SOON' || n.type == 'EXPIRED').length;
    final shoppingCount = allNotifications.where((n) => n.type == 'SHOPPING_LIST_UPDATE' || n.type == 'SYNC_COMPLETED' || n.type == 'FAMILY_ACTIVITY').length;

    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildFilterChip('ALL', 'All (${allNotifications.length})', Icons.notifications_none_rounded),
          const SizedBox(width: 8),
          _buildFilterChip('UNREAD', 'Unread ($unreadCount)', Icons.mark_email_unread_outlined),
          const SizedBox(width: 8),
          _buildFilterChip('STOCK', 'Stock ($stockCount)', Icons.inventory_2_outlined),
          const SizedBox(width: 8),
          _buildFilterChip('EXPIRY', 'Expiry ($expiryCount)', Icons.hourglass_bottom_rounded),
          const SizedBox(width: 8),
          _buildFilterChip('SHOPPING', 'Household ($shoppingCount)', Icons.shopping_bag_outlined),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, IconData icon) {
    final isSelected = _selectedFilter == filterKey;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = filterKey);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // 4. DATE SECTION HEADER
  // ==================================================
  Widget _buildDateSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ==================================================
  // 5. INDIVIDUAL NOTIFICATION CARD (With Swipe & Tap to Delete)
  // ==================================================
  Widget _buildNotificationCard(NotificationModel notif) {
    final styling = _getNotificationStyling(notif.type);
    final relativeTime = _formatRelativeTime(notif.createdAt);

    final lowerTitle = notif.title.toLowerCase();
    String? itemEmoji;
    if (lowerTitle.contains('milk')) {
      itemEmoji = '🥛';
    } else if (lowerTitle.contains('egg')) {
      itemEmoji = '🥚';
    } else if (lowerTitle.contains('onion')) {
      itemEmoji = '🧅';
    } else if (lowerTitle.contains('rice')) {
      itemEmoji = '🍚';
    } else if (lowerTitle.contains('cheese')) {
      itemEmoji = '🧀';
    } else if (lowerTitle.contains('bread')) {
      itemEmoji = '🍞';
    }

    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
      onDismissed: (_) {
        _deleteNotificationWithUndo(notif);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: InkWell(
          onTap: () {
            if (!notif.isRead) {
              ref.read(notificationControllerProvider.notifier).markAsRead(notif.id);
            }
            _handleNotificationTap(notif);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: notif.isRead ? Colors.white : const Color(0xFFFAF8FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: notif.isRead ? const Color(0xFFF1F5F9) : const Color(0xFFDDD6FE),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Visual Icon Container (44x44) + Badge & Title + Delete Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Container
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: styling.bgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: itemEmoji != null
                            ? Text(itemEmoji, style: const TextStyle(fontSize: 22))
                            : Icon(styling.icon, size: 22, color: styling.iconColor),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Metadata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge Pill + Relative Time + Unread Dot
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: styling.badgeBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  styling.badgeText,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: styling.badgeTextColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                relativeTime,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              if (!notif.isRead) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF6366F1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Notification Title
                          Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: notif.isRead ? FontWeight.w700 : FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Direct Delete Cross Button
                    InkWell(
                      onTap: () => _deleteNotificationWithUndo(notif),
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),

                // Body text (Aligned below title)
                Padding(
                  padding: const EdgeInsets.only(left: 56, top: 4),
                  child: Text(
                    notif.body,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Problem-matched CTA Action buttons
                _buildCardActions(notif),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================================================
  // 6. ACTION BUTTONS ON NOTIFICATION CARDS
  // ==================================================
  Widget _buildCardActions(NotificationModel notif) {
    final actions = <Widget>[];

    // Out of Stock / Low Stock / Smart Restock -> "+ Add to Shopping List"
    if (notif.type == 'OUT_OF_STOCK' ||
        notif.type == 'LOW_STOCK' ||
        notif.type == 'SMART_RESTOCK_SUGGESTION') {
      actions.add(
        ElevatedButton.icon(
          onPressed: () async {
            if (!notif.isRead) {
              ref.read(notificationControllerProvider.notifier).markAsRead(notif.id);
            }
            // Parse item name from title or body
            final parsedName = notif.title.replaceAll(RegExp(r'^(Low stock:|Out of stock:|Restock)'), '').trim();
            final success = await ref.read(shoppingControllerProvider.notifier).addItem(
                  inventoryItemId: notif.targetItemId,
                  itemName: parsedName.isNotEmpty ? parsedName : 'Pantry Essential',
                  quantity: 1.0,
                  unit: 'pcs',
                );
            if (mounted && success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Text('🛒', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Added "$parsedName" to Shopping List')),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF6366F1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
          label: const Text(
            '+ Add to Shopping',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            visualDensity: VisualDensity.compact,
          ),
        ),
      );

      if (notif.targetItemId != null && notif.targetItemId!.isNotEmpty) {
        actions.add(const SizedBox(width: 6));
        actions.add(
          OutlinedButton(
            onPressed: () {
              if (!notif.isRead) {
                ref.read(notificationControllerProvider.notifier).markAsRead(notif.id);
              }
              context.push('/inventory/detail/${notif.targetItemId}');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('View Item', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        );
      }
    } else if (notif.type == 'EXPIRY_REMINDER' || notif.type == 'EXPIRING_SOON' || notif.type == 'EXPIRED') {
      // Expiry Issue -> "Inspect Item"
      if (notif.targetItemId != null && notif.targetItemId!.isNotEmpty) {
        actions.add(
          ElevatedButton.icon(
            onPressed: () {
              if (!notif.isRead) {
                ref.read(notificationControllerProvider.notifier).markAsRead(notif.id);
              }
              context.push('/inventory/detail/${notif.targetItemId}');
            },
            icon: const Icon(Icons.visibility_outlined, size: 14),
            label: const Text('Inspect Item', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              visualDensity: VisualDensity.compact,
            ),
          ),
        );
      }
    } else if (notif.type == 'SHOPPING_LIST_UPDATE') {
      // Shopping List -> "View Shopping List"
      actions.add(
        ElevatedButton.icon(
          onPressed: () {
            if (!notif.isRead) {
              ref.read(notificationControllerProvider.notifier).markAsRead(notif.id);
            }
            context.push('/shopping');
          },
          icon: const Icon(Icons.shopping_bag_outlined, size: 14),
          label: const Text('View Shopping List', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            visualDensity: VisualDensity.compact,
          ),
        ),
      );
    } else if (notif.type == 'WEEKLY_INSIGHT' || notif.type == 'MONTHLY_REPORT') {
      actions.add(
        ElevatedButton.icon(
          onPressed: () {
            if (!notif.isRead) {
              ref.read(notificationControllerProvider.notifier).markAsRead(notif.id);
            }
            context.push('/analytics');
          },
          icon: const Icon(Icons.insights_rounded, size: 14),
          label: const Text('View Insights', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            visualDensity: VisualDensity.compact,
          ),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 56),
      child: Row(children: actions),
    );
  }

  // ==================================================
  // 7. DELETION LOGIC (With Undo SnackBar)
  // ==================================================
  void _deleteNotificationWithUndo(NotificationModel notif) {
    HapticFeedback.mediumImpact();
    ref.read(notificationControllerProvider.notifier).deleteNotification(notif.id);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Deleted "${notif.title}"',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: const Color(0xFFFDE047),
          onPressed: () {
            ref.read(notificationControllerProvider.notifier).restoreNotification(notif);
          },
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  /// Confirmation dialog before clearing all notifications
  void _showClearAllConfirmation(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.delete_sweep_rounded, size: 28, color: Color(0xFFDC2626)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Clear All Notifications?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will permanently delete all notifications from your notification history.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Keep',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(notificationControllerProvider.notifier).clearAllNotifications();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('All notifications cleared'),
                              ],
                            ),
                            duration: const Duration(seconds: 2),
                            backgroundColor: const Color(0xFF1E293B),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================================================
  // 8. CALM EMPTY STATE
  // ==================================================
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F3FF),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.notifications_none_rounded, size: 38, color: Color(0xFF7C3AED)),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _selectedFilter == 'UNREAD' ? 'No unread notifications' : 'All caught up!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _selectedFilter == 'UNREAD'
                  ? 'You have reviewed all your household alerts.'
                  : 'Low stock alerts, expiry reminders, and family activity will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.push('/settings/notifications'),
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const Text('Manage Preferences', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // 9. HELPER METHODS & STYLING
  // ==================================================
  List<NotificationModel> _filterNotifications(List<NotificationModel> list, String filter) {
    switch (filter) {
      case 'UNREAD':
        return list.where((n) => !n.isRead).toList();
      case 'STOCK':
        return list.where((n) => n.type == 'OUT_OF_STOCK' || n.type == 'LOW_STOCK' || n.type == 'SMART_RESTOCK_SUGGESTION').toList();
      case 'EXPIRY':
        return list.where((n) => n.type == 'EXPIRY_REMINDER' || n.type == 'EXPIRING_SOON' || n.type == 'EXPIRED').toList();
      case 'SHOPPING':
        return list.where((n) => n.type == 'SHOPPING_LIST_UPDATE' || n.type == 'SYNC_COMPLETED' || n.type == 'FAMILY_ACTIVITY').toList();
      case 'ALL':
      default:
        return list;
    }
  }

  String _formatRelativeTime(String isoString) {
    final date = DateTime.tryParse(isoString)?.toLocal();
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24 && date.day == now.day) {
      return DateFormat('h:mm a').format(date);
    }
    if (diff.inDays == 1 || (diff.inHours < 48 && date.day == now.day - 1)) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    }
    return DateFormat('MMM d, h:mm a').format(date);
  }

  Future<void> _handleRefresh(WidgetRef ref) async {
    final activeHome = ref.read(homeControllerProvider).activeHome;
    if (activeHome != null) {
      await ref.read(notificationControllerProvider.notifier).runLocalScan(activeHome.id);
    } else {
      await ref.read(notificationControllerProvider.notifier).loadNotifications();
    }
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
          iconColor: const Color(0xFFDC2626),
          bgColor: const Color(0xFFFEF2F2),
          badgeText: '🔴 OUT OF STOCK',
          badgeBg: const Color(0xFFFEE2E2),
          badgeTextColor: const Color(0xFFB91C1C),
        );
      case 'LOW_STOCK':
        return _NotificationStyling(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFD97706),
          bgColor: const Color(0xFFFEF9C3),
          badgeText: '⚠️ LOW STOCK',
          badgeBg: const Color(0xFFFEF3C7),
          badgeTextColor: const Color(0xFFB45309),
        );
      case 'EXPIRY_REMINDER':
      case 'EXPIRING_SOON':
        return _NotificationStyling(
          icon: Icons.hourglass_bottom_rounded,
          iconColor: const Color(0xFFD97706),
          bgColor: const Color(0xFFFEF9C3),
          badgeText: '⏳ EXPIRING SOON',
          badgeBg: const Color(0xFFFFEDD5),
          badgeTextColor: const Color(0xFFC2410C),
        );
      case 'EXPIRED':
        return _NotificationStyling(
          icon: Icons.timer_off_outlined,
          iconColor: const Color(0xFFDC2626),
          bgColor: const Color(0xFFFEF2F2),
          badgeText: '⏰ EXPIRED',
          badgeBg: const Color(0xFFFEE2E2),
          badgeTextColor: const Color(0xFFB91C1C),
        );
      case 'SHOPPING_LIST_UPDATE':
        return _NotificationStyling(
          icon: Icons.shopping_bag_outlined,
          iconColor: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFF3E8FF),
          badgeText: '🛒 SHOPPING',
          badgeBg: const Color(0xFFEDE9FE),
          badgeTextColor: const Color(0xFF6D28D9),
        );
      case 'STOCK_UPDATED':
      case 'PURCHASE_RECORDED':
        return _NotificationStyling(
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF16A34A),
          bgColor: const Color(0xFFDCFCE7),
          badgeText: '✓ RESTOCKED',
          badgeBg: const Color(0xFFDCFCE7),
          badgeTextColor: const Color(0xFF15803D),
        );
      case 'SMART_RESTOCK_SUGGESTION':
      case 'WEEKLY_INSIGHT':
      case 'MONTHLY_REPORT':
        return _NotificationStyling(
          icon: Icons.auto_awesome_rounded,
          iconColor: const Color(0xFF6D28D9),
          bgColor: const Color(0xFFEDE9FE),
          badgeText: '✨ SMART INSIGHT',
          badgeBg: const Color(0xFFEDE9FE),
          badgeTextColor: const Color(0xFF5B21B6),
        );
      case 'SYNC_COMPLETED':
        return _NotificationStyling(
          icon: Icons.cloud_done_outlined,
          iconColor: const Color(0xFF16A34A),
          bgColor: const Color(0xFFDCFCE7),
          badgeText: '☁️ SYNCED',
          badgeBg: const Color(0xFFDCFCE7),
          badgeTextColor: const Color(0xFF15803D),
        );
      case 'FAMILY_ACTIVITY':
      default:
        return _NotificationStyling(
          icon: Icons.people_outline_rounded,
          iconColor: const Color(0xFF0284C7),
          bgColor: const Color(0xFFE0F2FE),
          badgeText: '🏠 HOUSEHOLD',
          badgeBg: const Color(0xFFDBEAFE),
          badgeTextColor: const Color(0xFF0369A1),
        );
    }
  }
}

class _NotificationStyling {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String badgeText;
  final Color badgeBg;
  final Color badgeTextColor;

  _NotificationStyling({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeTextColor,
  });
}
