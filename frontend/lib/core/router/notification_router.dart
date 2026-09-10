import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';
import '../../features/home_switcher/home_controller.dart';
import '../../features/notifications/notification_model.dart';
import '../sync/sync_providers.dart';

/// Centralized notification routing with multi-home isolation.
///
/// Before navigating, verifies the user is a member of the notification's
/// home and switches the active home context if needed. All notification
/// taps (FCM, local heads-up, in-app list) funnel through this router.
class NotificationRouter {
  final WidgetRef _ref;

  NotificationRouter(this._ref);

  /// Route a notification tap — switches home if necessary, then navigates.
  Future<void> routeNotification({
    required BuildContext context,
    required String? homeId,
    required String? entityId,
    required String? entityType,
    required String? action,
    required String? notificationType,
  }) async {
    // 1. Switch home if the notification targets a different home
    if (homeId != null && homeId.isNotEmpty) {
      final activeHomeId = _ref.read(homeControllerProvider).activeHome?.id;
      if (activeHomeId != homeId) {
        final switched = await _ref
            .read(homeControllerProvider.notifier)
            .switchHomeById(homeId);
        if (switched == null) {
          debugPrint(
              '[NotificationRouter] User not a member of home $homeId — aborting navigation');
          return;
        }
        // Trigger sync for the newly active home
        _ref.read(syncEngineProvider).syncHome(homeId);
      }
    }

    // 2. Determine route based on entity type / action / notification type
    final route = _resolveRoute(
      entityId: entityId,
      entityType: entityType,
      action: action,
      notificationType: notificationType,
    );

    if (route != null && context.mounted) {
      GoRouter.of(context).push(route);
    }
  }

  /// Route from a [NotificationModel] (in-app notification list tap).
  Future<void> routeNotificationModel({
    required BuildContext context,
    required NotificationModel notif,
  }) {
    return routeNotification(
      context: context,
      homeId: notif.homeId.isNotEmpty ? notif.homeId : null,
      entityId: notif.targetItemId,
      entityType: notif.entityType,
      action: notif.action,
      notificationType: notif.type,
    );
  }

  /// Route from an FCM / local-notification payload map.
  Future<void> routeFromPayload({
    required BuildContext context,
    required Map<String, dynamic> payload,
  }) {
    return routeNotification(
      context: context,
      homeId: payload['homeId']?.toString(),
      entityId:
          payload['entityId']?.toString() ?? payload['itemId']?.toString(),
      entityType: payload['entityType']?.toString(),
      action: payload['action']?.toString(),
      notificationType: payload['type']?.toString(),
    );
  }

  /// Resolve route string from notification metadata.
  static String? _resolveRoute({
    String? entityId,
    String? entityType,
    String? action,
    String? notificationType,
  }) {
    final type = (notificationType ?? '').toUpperCase();
    final eType = (entityType ?? '').toUpperCase();
    final act = (action ?? '').toUpperCase();

    // Inventory item deep link
    if (entityId != null && entityId.isNotEmpty) {
      if (eType == 'INVENTORY_ITEM' ||
          type == 'LOW_STOCK' ||
          type == 'OUT_OF_STOCK' ||
          type == 'STOCK_UPDATED' ||
          type == 'EXPIRY_REMINDER' ||
          type == 'EXPIRING_SOON' ||
          type == 'EXPIRED' ||
          type == 'SMART_RESTOCK_SUGGESTION') {
        return '/inventory/detail/$entityId';
      }
    }

    // Shopping list deep link
    if (type == 'SHOPPING_LIST_UPDATE' ||
        eType == 'SHOPPING_LIST' ||
        eType == 'SHOPPING_LIST_ITEM' ||
        act == 'SHOPPING') {
      return '/shopping';
    }

    // Purchase deep link
    if (type == 'PURCHASE_RECORDED' ||
        eType == 'PURCHASE' ||
        act == 'PURCHASE') {
      // PurchasesScreen is navigator-pushed, not a go_router path,
      // so we fall back to shopping which contains the purchase link.
      return '/shopping';
    }

    // Analytics deep link
    if (type == 'WEEKLY_INSIGHT' ||
        type == 'MONTHLY_REPORT' ||
        act == 'ANALYTICS') {
      return '/analytics';
    }

    // Fallback — inventory item if entityId exists
    if (entityId != null && entityId.isNotEmpty) {
      return '/inventory/detail/$entityId';
    }

    // No deep link — go to notifications list
    return '/notifications';
  }
}
