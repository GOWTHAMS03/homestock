import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homestock/core/widgets/offline_wifi_badge.dart';
import 'package:homestock/core/sync/sync_providers.dart';
import 'package:homestock/core/sync/sync_status.dart';

void main() {
  group('OfflineWifiBadge Widget Tests', () {
    testWidgets('renders SizedBox.shrink when online and not syncing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStateProvider.overrideWith(
              (ref) => Stream.value(const SyncState(
                status: NetworkStatus.online,
                isSyncInProgress: false,
              )),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineWifiBadge(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Offline'), findsNothing);
      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
    });

    testWidgets('renders compact wifi off badge when offline', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStateProvider.overrideWith(
              (ref) => Stream.value(const SyncState(
                status: NetworkStatus.offline,
                pendingOperationsCount: 2,
              )),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineWifiBadge(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('renders spinning sync indicator when syncing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStateProvider.overrideWith(
              (ref) => Stream.value(const SyncState(
                status: NetworkStatus.syncing,
                isSyncInProgress: true,
              )),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineWifiBadge(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('tapping offline badge opens SnackBar with retry', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStateProvider.overrideWith(
              (ref) => Stream.value(const SyncState(
                status: NetworkStatus.offline,
                pendingOperationsCount: 1,
              )),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(child: OfflineWifiBadge()),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(OfflineWifiBadge));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
