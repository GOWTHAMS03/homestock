import 'package:flutter/material.dart';

class NotificationPreferenceModel {
  final bool lowStockEnabled;
  final bool outOfStockEnabled;
  final bool expiryEnabled;
  final bool shoppingListEnabled;
  final bool familyActivityEnabled;
  final bool purchaseEnabled;
  final bool smartSuggestionEnabled;
  final bool weeklyInsightEnabled;
  final bool monthlyReportEnabled;
  final bool quietHoursEnabled;
  final String quietHoursStart; // Format: "HH:mm:ss" or "HH:mm"
  final String quietHoursEnd;   // Format: "HH:mm:ss" or "HH:mm"

  const NotificationPreferenceModel({
    this.lowStockEnabled = true,
    this.outOfStockEnabled = true,
    this.expiryEnabled = true,
    this.shoppingListEnabled = true,
    this.familyActivityEnabled = true,
    this.purchaseEnabled = true,
    this.smartSuggestionEnabled = true,
    this.weeklyInsightEnabled = true,
    this.monthlyReportEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00:00',
    this.quietHoursEnd = '07:00:00',
  });

  TimeOfDay get startTimeOfDay {
    try {
      final parts = quietHoursStart.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 22, minute: 0);
    }
  }

  TimeOfDay get endTimeOfDay {
    try {
      final parts = quietHoursEnd.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 7, minute: 0);
    }
  }

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceModel(
      lowStockEnabled: json['lowStockEnabled'] ?? true,
      outOfStockEnabled: json['outOfStockEnabled'] ?? true,
      expiryEnabled: json['expiryEnabled'] ?? true,
      shoppingListEnabled: json['shoppingListEnabled'] ?? true,
      familyActivityEnabled: json['familyActivityEnabled'] ?? true,
      purchaseEnabled: json['purchaseEnabled'] ?? true,
      smartSuggestionEnabled: json['smartSuggestionEnabled'] ?? true,
      weeklyInsightEnabled: json['weeklyInsightEnabled'] ?? true,
      monthlyReportEnabled: json['monthlyReportEnabled'] ?? true,
      quietHoursEnabled: json['quietHoursEnabled'] ?? false,
      quietHoursStart: json['quietHoursStart']?.toString() ?? '22:00:00',
      quietHoursEnd: json['quietHoursEnd']?.toString() ?? '07:00:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lowStockEnabled': lowStockEnabled,
      'outOfStockEnabled': outOfStockEnabled,
      'expiryEnabled': expiryEnabled,
      'shoppingListEnabled': shoppingListEnabled,
      'familyActivityEnabled': familyActivityEnabled,
      'purchaseEnabled': purchaseEnabled,
      'smartSuggestionEnabled': smartSuggestionEnabled,
      'weeklyInsightEnabled': weeklyInsightEnabled,
      'monthlyReportEnabled': monthlyReportEnabled,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart.length == 5 ? '$quietHoursStart:00' : quietHoursStart,
      'quietHoursEnd': quietHoursEnd.length == 5 ? '$quietHoursEnd:00' : quietHoursEnd,
    };
  }

  NotificationPreferenceModel copyWith({
    bool? lowStockEnabled,
    bool? outOfStockEnabled,
    bool? expiryEnabled,
    bool? shoppingListEnabled,
    bool? familyActivityEnabled,
    bool? purchaseEnabled,
    bool? smartSuggestionEnabled,
    bool? weeklyInsightEnabled,
    bool? monthlyReportEnabled,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationPreferenceModel(
      lowStockEnabled: lowStockEnabled ?? this.lowStockEnabled,
      outOfStockEnabled: outOfStockEnabled ?? this.outOfStockEnabled,
      expiryEnabled: expiryEnabled ?? this.expiryEnabled,
      shoppingListEnabled: shoppingListEnabled ?? this.shoppingListEnabled,
      familyActivityEnabled: familyActivityEnabled ?? this.familyActivityEnabled,
      purchaseEnabled: purchaseEnabled ?? this.purchaseEnabled,
      smartSuggestionEnabled: smartSuggestionEnabled ?? this.smartSuggestionEnabled,
      weeklyInsightEnabled: weeklyInsightEnabled ?? this.weeklyInsightEnabled,
      monthlyReportEnabled: monthlyReportEnabled ?? this.monthlyReportEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}

