import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/theme/app_theme.dart';
import 'package:homestock/core/widgets/in_app_notification_banner.dart';
import 'package:homestock/features/notifications/notification_controller.dart';
import 'package:homestock/features/notifications/notification_preference_model.dart';
import 'package:homestock/features/notifications/notification_preferences_screen.dart';

class MockNotificationController extends StateNotifier<NotificationState>
    implements NotificationController {
  MockNotificationController(super.state);

  @override
  Future<void> loadNotifications() async {}

  @override
  Future<void> loadPreferences() async {}

  @override
  Future<void> updatePreferences(NotificationPreferenceModel updated) async {
    state = state.copyWith(preferences: updated);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('InAppNotificationBanner renders with project theme styling, badges, and action buttons',
      (WidgetTester tester) async {
    bool tapped = false;
    bool actionTapped = false;
    bool dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Stack(
            children: [
              InAppNotificationBanner(
                title: 'Milk (பால்) is running low',
                body: 'Only 0.5 L remaining in Refrigerator.',
                type: 'LOW_STOCK',
                onTap: () => tapped = true,
                onActionTap: () => actionTapped = true,
                onDismiss: () => dismissed = true,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title, body, badge, and action button are displayed
    expect(find.text('Milk (பால்) is running low'), findsOneWidget);
    expect(find.text('Only 0.5 L remaining in Refrigerator.'), findsOneWidget);
    expect(tapped, isFalse);
    expect(find.text('⚠️ LOW STOCK'), findsOneWidget);
    expect(find.text('+ Add to Shopping'), findsOneWidget);
    expect(find.text('Just now'), findsOneWidget);

    // Test action button tap
    await tester.tap(find.text('+ Add to Shopping'));
    await tester.pumpAndSettle();
    expect(actionTapped, isTrue);
    expect(dismissed, isTrue);
  });

  testWidgets('NotificationPreferencesScreen renders redesigned Firebase Realtime Push card',
      (WidgetTester tester) async {
    final mockCtrl = MockNotificationController(
      const NotificationState(
        isPreferencesLoading: false,
        preferences: NotificationPreferenceModel(),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationControllerProvider.overrideWith((ref) => mockCtrl),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NotificationPreferencesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Firebase card header elements
    expect(find.text('Firebase Cloud Push'), findsOneWidget);
    expect(find.text('Realtime alerts for stockouts, expiries & sync'), findsOneWidget);

    // Verify Preview Section
    expect(find.text('NOTIFICATION CARD PREVIEW'), findsOneWidget);
    expect(find.text('Project Theme'), findsOneWidget);
    expect(find.text('Milk (பால்) is running low'), findsOneWidget);
    expect(find.text('⚡ Realtime Push'), findsOneWidget);

    // Verify Scenario Chips
    expect(find.text('🥛 Low Stock'), findsOneWidget);
    expect(find.text('⏳ Expiry'), findsOneWidget);
    expect(find.text('🛒 Shopping'), findsOneWidget);

    // Switch scenario to Expiry
    await tester.tap(find.text('⏳ Expiry'));
    await tester.pumpAndSettle();

    // Verify preview card updated to Expiry
    expect(find.text('Eggs Expiring in 3 Days'), findsOneWidget);
    expect(find.text('⏳ EXPIRING SOON'), findsOneWidget);
    expect(find.text('Inspect Item'), findsOneWidget);

    // Verify Send Test Notification button
    expect(find.text('Send Test Notification'), findsOneWidget);
  });
}
