import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/notifications/notification_service.dart';
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
  group('NotificationCardStyler Unit Tests', () {
    test('resolves Low Stock card preview with amber styling and critical group', () {
      final style = NotificationCardStyler.resolve(
        type: 'LOW_STOCK',
        title: 'Milk (பால்) is running low',
        body: 'Only 0.5 L remaining in Refrigerator.',
      );

      expect(style.badgeText, '⚠️ LOW STOCK');
      expect(style.emoji, '🥛');
      expect(style.accentColor, const Color(0xFFD97706));
      expect(style.groupKey, NotificationCardStyler.groupStockExpiry);
      expect(style.groupSummaryId, NotificationCardStyler.groupStockExpirySummaryId);
      expect(style.groupTitle, 'Stock & Expiry Alerts');
      expect(style.actions.any((a) => a.id == 'action_shopping'), isTrue);
      expect(style.actions.any((a) => a.id == 'action_inspect'), isTrue);
    });

    test('resolves Expiry card preview with orange styling and critical group', () {
      final style = NotificationCardStyler.resolve(
        type: 'EXPIRING_SOON',
        title: 'Eggs Expiring in 3 Days',
        body: '24 pcs remaining • Use soon to avoid waste',
      );

      expect(style.badgeText, '⏳ EXPIRING SOON');
      expect(style.emoji, '🥚');
      expect(style.accentColor, const Color(0xFFEA580C));
      expect(style.groupKey, NotificationCardStyler.groupStockExpiry);
      expect(style.actions.any((a) => a.id == 'action_inspect'), isTrue);
    });

    test('resolves Shopping List card preview with purple styling and activity group', () {
      final style = NotificationCardStyler.resolve(
        type: 'SHOPPING_LIST_UPDATE',
        title: 'Shopping List Updated',
        body: 'Gowtham added Rice (2 kg)',
      );

      expect(style.badgeText, '🛒 SHOPPING LIST');
      expect(style.emoji, '🛒');
      expect(style.accentColor, const Color(0xFF7C3AED));
      expect(style.groupKey, NotificationCardStyler.groupActivity);
      expect(style.groupTitle, 'Household Activity');
      expect(style.actions.any((a) => a.id == 'action_shopping'), isTrue);
    });

    test('resolves Multi-Item Restock Digest with digest badge and insights group', () {
      final style = NotificationCardStyler.resolve(
        type: 'SMART_RESTOCK_SUGGESTION',
        title: '🛒 3 items may run out soon',
        body: 'Whole Milk, Brown Eggs, Bread may need restocking soon.',
        payload: {
          'isDigest': 'true',
          'itemCount': '3',
          'estimatedTotalCost': '320.00',
        },
      );

      expect(style.badgeText, '🛒 RESTOCK DIGEST');
      expect(style.emoji, '🛒');
      expect(style.accentColor, const Color(0xFF6366F1));
      expect(style.groupKey, NotificationCardStyler.groupInsights);
      expect(style.groupTitle, 'Smart Insights & Digests');
      expect(style.actions.any((a) => a.id == 'action_shopping'), isTrue);
    });
  });

  group('InAppNotificationBanner Widget Tests', () {
    testWidgets('renders with project theme styling, badges, and action buttons',
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

    testWidgets('renders multi-item digest notification card styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Stack(
              children: [
                InAppNotificationBanner(
                  title: '🛒 3 items may run out soon',
                  body: 'Whole Milk, Brown Eggs, Bread may need restocking.',
                  type: 'SMART_RESTOCK_SUGGESTION',
                  payload: const {
                    'isDigest': 'true',
                    'itemCount': '3',
                  },
                  onDismiss: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify digest pill badge and action button
      expect(find.text('🛒 RESTOCK DIGEST'), findsOneWidget);
      expect(find.text('🛒 3 items may run out soon'), findsOneWidget);
      expect(find.text('View Shopping List'), findsOneWidget);
    });

    testWidgets('displays +N more pill badge when queuedCount > 1',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Stack(
              children: [
                InAppNotificationBanner(
                  title: 'Eggs Expiring Soon',
                  body: '24 pcs remaining • Use soon',
                  type: 'EXPIRING_SOON',
                  queuedCount: 3,
                  onDismiss: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify +2 more indicator is displayed
      expect(find.text('+2 more'), findsOneWidget);
      expect(find.text('⏳ EXPIRING SOON'), findsOneWidget);
    });
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
