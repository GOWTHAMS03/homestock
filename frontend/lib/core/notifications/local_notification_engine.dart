import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/daos/inventory_dao.dart';
import '../database/daos/notification_dao.dart';
import 'notification_service.dart';

/// Offline-first notification engine that runs on-device without internet.
/// Inspects local SQLite inventory for stock levels, expiration dates,
/// and consumption patterns with cooldown-based deduplication.
class LocalNotificationEngine {
  final InventoryDao _inventoryDao;
  final NotificationDao _notificationDao;
  final NotificationService _notificationService;
  final Uuid _uuid = const Uuid();

  // Cooldown map: dedupKey -> timestamp of last alert
  final Map<String, DateTime> _cooldowns = {};

  static const Duration stockCooldown = Duration(hours: 12);
  static const Duration expiryCooldown = Duration(hours: 24);
  static const Duration restockCooldown = Duration(days: 2);

  LocalNotificationEngine({
    required InventoryDao inventoryDao,
    required NotificationDao notificationDao,
    NotificationService? notificationService,
  })  : _inventoryDao = inventoryDao,
        _notificationDao = notificationDao,
        _notificationService = notificationService ?? NotificationService.instance;

  /// Trigger an offline scan for a specific home.
  Future<void> scanInventory(String homeId, {String? userId}) async {
    try {
      final items = await _inventoryDao.getAllItems(homeId);
      final now = DateTime.now();

      for (final item in items) {
        if (item.isDeleted) continue;

        // 1. Out of Stock check
        if (item.quantity <= 0) {
          await _checkAndAlert(
            dedupKey: 'OUT_OF_STOCK:${item.id}',
            cooldown: stockCooldown,
            type: 'OUT_OF_STOCK',
            title: 'Out of Stock: ${item.name}',
            body: 'You are completely out of ${item.name}. Add it to your shopping list?',
            channelId: NotificationService.channelImportant,
            itemId: item.id,
            homeId: homeId,
            userId: userId ?? 'local_user',
          );
          continue; // Don't also fire low stock
        }

        // 2. Low Stock check
        if (item.quantity <= item.minimumQuantity) {
          await _checkAndAlert(
            dedupKey: 'LOW_STOCK:${item.id}',
            cooldown: stockCooldown,
            type: 'LOW_STOCK',
            title: 'Low Stock: ${item.name}',
            body: 'Only ${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} ${item.unit} remaining (minimum: ${item.minimumQuantity.toStringAsFixed(0)}).',
            channelId: NotificationService.channelImportant,
            itemId: item.id,
            homeId: homeId,
            userId: userId ?? 'local_user',
          );
        }

        // 3. Expiry check
        if (item.expiryDate != null && item.expiryDate!.isNotEmpty) {
          final expiry = DateTime.tryParse(item.expiryDate!);
          if (expiry != null) {
            final daysUntil = expiry.difference(now).inDays;
            if (daysUntil < 0) {
              await _checkAndAlert(
                dedupKey: 'EXPIRED:${item.id}',
                cooldown: expiryCooldown,
                type: 'EXPIRY_REMINDER',
                title: 'Expired: ${item.name}',
                body: '${item.name} expired on ${item.expiryDate}. Please inspect or discard.',
                channelId: NotificationService.channelImportant,
                itemId: item.id,
                homeId: homeId,
                userId: userId ?? 'local_user',
              );
            } else if (daysUntil <= 3) {
              final daysLabel = daysUntil == 0 ? 'today' : (daysUntil == 1 ? 'tomorrow' : 'in $daysUntil days');
              await _checkAndAlert(
                dedupKey: 'EXPIRING:${item.id}',
                cooldown: expiryCooldown,
                type: 'EXPIRY_REMINDER',
                title: 'Expiring Soon: ${item.name}',
                body: '${item.name} expires $daysLabel. Plan to consume or use it soon.',
                channelId: NotificationService.channelImportant,
                itemId: item.id,
                homeId: homeId,
                userId: userId ?? 'local_user',
              );
            }
          }
        }

        // 4. Smart Restock Suggestion (using local consumption prediction)
        if (item.estimatedDaysRemaining != null &&
            item.estimatedDaysRemaining! <= 2 &&
            item.quantity > item.minimumQuantity) {
          await _checkAndAlert(
            dedupKey: 'SMART_RESTOCK:${item.id}',
            cooldown: restockCooldown,
            type: 'SMART_RESTOCK_SUGGESTION',
            title: 'Smart Restock: ${item.name}',
            body: 'Based on your usage, ${item.name} may run out in ~${item.estimatedDaysRemaining} days.',
            channelId: NotificationService.channelInsights,
            itemId: item.id,
            homeId: homeId,
            userId: userId ?? 'local_user',
          );
        }
      }
    } catch (e) {
      debugPrint('[LocalNotificationEngine] Error scanning inventory: $e');
    }
  }

  Future<void> _checkAndAlert({
    required String dedupKey,
    required Duration cooldown,
    required String type,
    required String title,
    required String body,
    required String channelId,
    required String itemId,
    required String homeId,
    required String userId,
  }) async {
    final now = DateTime.now();
    final lastAlert = _cooldowns[dedupKey];

    if (lastAlert != null && now.difference(lastAlert) < cooldown) {
      // Suppress alert within cooldown window
      return;
    }

    _cooldowns[dedupKey] = now;

    final notifId = _uuid.v4();
    final intNotificationId = dedupKey.hashCode.abs();
    final payloadMap = {
      'id': notifId,
      'itemId': itemId,
      'entityId': itemId,
      'homeId': homeId,
      'type': type,
      'entityType': 'INVENTORY_ITEM',
      'action': type,
      'screen': 'inventory_detail',
    };
    final payloadString = jsonEncode(payloadMap);

    // 1. Save to local SQLite database so in-app notifications screen shows it
    try {
      await _notificationDao.upsertNotification(
        LocalNotificationsCompanion(
          id: drift.Value(notifId),
          userId: drift.Value(userId),
          homeId: drift.Value(homeId),
          entityId: drift.Value(itemId),
          entityType: const drift.Value('INVENTORY_ITEM'),
          action: drift.Value(type),
          title: drift.Value(title),
          message: drift.Value(body),
          type: drift.Value(type),
          isRead: const drift.Value(false),
          createdAt: drift.Value(now),
        ),
      );
    } catch (e) {
      debugPrint('[LocalNotificationEngine] Failed to persist local notification: $e');
    }

    // 2. Show heads-up system notification
    try {
      await _notificationService.showNotification(
        id: intNotificationId,
        title: title,
        body: body,
        channelId: channelId,
        payload: payloadString,
      );
    } catch (e) {
      debugPrint('[LocalNotificationEngine] Failed to display system notification: $e');
    }
  }

  /// Reset cooldowns (e.g. for testing)
  void resetCooldowns() {
    _cooldowns.clear();
  }
}

