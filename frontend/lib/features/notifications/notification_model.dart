import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import '../../core/database/app_database.dart';

enum NotificationType {
  lowStock('LOW_STOCK'),
  outOfStock('OUT_OF_STOCK'),
  expiryReminder('EXPIRY_REMINDER'),
  shoppingListUpdate('SHOPPING_LIST_UPDATE'),
  familyActivity('FAMILY_ACTIVITY'),
  purchaseRecorded('PURCHASE_RECORDED'),
  stockUpdated('STOCK_UPDATED'),
  smartRestockSuggestion('SMART_RESTOCK_SUGGESTION'),
  weeklyInsight('WEEKLY_INSIGHT'),
  monthlyReport('MONTHLY_REPORT'),
  syncCompleted('SYNC_COMPLETED'),
  system('SYSTEM');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String? type) {
    if (type == null) return NotificationType.system;
    final upper = type.toUpperCase().trim();
    // Handle backward compatibility aliases
    if (upper == 'EXPIRING_SOON' || upper == 'EXPIRED') {
      return NotificationType.expiryReminder;
    }
    for (final val in NotificationType.values) {
      if (val.value == upper) return val;
    }
    return NotificationType.system;
  }
}

enum NotificationPriority {
  high('HIGH'),
  medium('MEDIUM'),
  low('LOW');

  final String value;
  const NotificationPriority(this.value);

  static NotificationPriority fromString(String? priority) {
    if (priority == null) return NotificationPriority.medium;
    final upper = priority.toUpperCase().trim();
    for (final val in NotificationPriority.values) {
      if (val.value == upper) return val;
    }
    return NotificationPriority.medium;
  }
}

class NotificationModel {
  final String id;
  final String homeId;
  final String type;
  final String priority;
  final String title;
  final String body;
  final String? payloadJson;
  final String? entityId;
  final String? entityType;
  final String? action;
  final bool isRead;
  final String createdAt;
  final String? readAt;

  NotificationModel({
    required this.id,
    required this.homeId,
    required this.type,
    this.priority = 'MEDIUM',
    required this.title,
    required this.body,
    this.payloadJson,
    this.entityId,
    this.entityType,
    this.action,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  NotificationType get typedType => NotificationType.fromString(type);
  NotificationPriority get typedPriority => NotificationPriority.fromString(priority);

  Map<String, dynamic> get payload {
    if (payloadJson == null || payloadJson!.isEmpty) return {};
    try {
      return jsonDecode(payloadJson!) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String? get targetItemId =>
      entityId ?? payload['entityId']?.toString() ?? payload['itemId']?.toString();
  String? get targetShoppingListId => payload['shoppingListId']?.toString();
  String? get targetScreen => action ?? payload['action']?.toString() ?? payload['screen']?.toString();

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final payloadObj = json['payload'] ?? json['data'];
    String? payloadStr = json['payloadJson']?.toString();
    if (payloadStr == null && payloadObj != null) {
      if (payloadObj is String) {
        payloadStr = payloadObj;
      } else {
        try {
          payloadStr = jsonEncode(payloadObj);
        } catch (_) {}
      }
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      homeId: json['homeId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'SYSTEM',
      priority: json['priority']?.toString() ?? 'MEDIUM',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? json['message']?.toString() ?? '',
      payloadJson: payloadStr,
      entityId: json['entityId']?.toString(),
      entityType: json['entityType']?.toString(),
      action: json['action']?.toString(),
      isRead: json['isRead'] == true,
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      readAt: json['readAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeId': homeId,
      'type': type,
      'priority': priority,
      'title': title,
      'body': body,
      'payloadJson': payloadJson,
      'entityId': entityId,
      'entityType': entityType,
      'action': action,
      'isRead': isRead,
      'createdAt': createdAt,
      'readAt': readAt,
    };
  }

  /// Convert from Drift SQLite entity
  factory NotificationModel.fromLocal(LocalNotification row) {
    return NotificationModel(
      id: row.id,
      homeId: row.homeId,
      type: row.type ?? 'SYSTEM',
      priority: 'MEDIUM',
      title: row.title,
      body: row.message,
      entityId: row.entityId,
      entityType: row.entityType,
      action: row.action,
      isRead: row.isRead,
      createdAt: row.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    );
  }

  /// Convert to Drift companion for caching in SQLite
  LocalNotificationsCompanion toLocalCompanion(String userId) {
    return LocalNotificationsCompanion(
      id: drift.Value(id),
      userId: drift.Value(userId),
      homeId: drift.Value(homeId),
      title: drift.Value(title),
      message: drift.Value(body),
      type: drift.Value(type),
      entityId: drift.Value(entityId ?? targetItemId),
      entityType: drift.Value(entityType ?? payload['entityType']?.toString()),
      action: drift.Value(action ?? targetScreen),
      isRead: drift.Value(isRead),
      createdAt: drift.Value(DateTime.tryParse(createdAt) ?? DateTime.now()),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? homeId,
    String? type,
    String? priority,
    String? title,
    String? body,
    String? payloadJson,
    String? entityId,
    String? entityType,
    String? action,
    bool? isRead,
    String? createdAt,
    String? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      body: body ?? this.body,
      payloadJson: payloadJson ?? this.payloadJson,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      action: action ?? this.action,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
