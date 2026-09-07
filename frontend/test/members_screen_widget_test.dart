import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/network/api_client.dart';
import 'package:homestock/core/storage/secure_storage_service.dart';
import 'package:homestock/core/theme/app_theme.dart';
import 'package:homestock/core/sync/sync_providers.dart';
import 'package:homestock/core/sync/sync_status.dart';
import 'package:homestock/features/auth/auth_controller.dart';
import 'package:homestock/features/auth/auth_state.dart';
import 'package:homestock/features/home_switcher/home_controller.dart';
import 'package:homestock/features/home_switcher/home_model.dart';
import 'package:homestock/features/home_switcher/home_repository.dart';
import 'package:homestock/features/home_switcher/members_screen.dart';

class FakeHomeRepo extends HomeRepository {
  FakeHomeRepo()
      : super(
          apiClient: ApiClient(secureStorage: SecureStorageService()),
          storage: SecureStorageService(),
        );

  @override
  Future<List<HomeMemberModel>> getMembers(String homeId) async => [];
}

class MockHomeController extends HomeController {
  MockHomeController(HomeState initial)
      : super(FakeHomeRepo(), SecureStorageService()) {
    state = initial;
  }

  @override
  Future<void> loadHomes() async {}
}

class MockMembersController extends MembersController {
  MockMembersController(MembersState initial)
      : super(FakeHomeRepo(), 'home-123') {
    state = initial;
  }

  @override
  Future<void> loadMembers() async {}
}

class MockAuthController extends StateNotifier<AuthState> implements AuthController {
  MockAuthController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('MembersScreen renders cleanly with AppTheme and without layout exceptions',
      (WidgetTester tester) async {
    final testHome = HomeModel(
      id: 'home-123',
      name: 'Test Family Household',
      inviteCode: 'TEST1234',
      currentUserRole: 'OWNER',
      memberCount: 2,
    );

    final testMembers = [
      HomeMemberModel(
        id: 'mem-1',
        userId: 'u-1',
        fullName: 'Test Owner',
        email: 'owner@example.com',
        role: 'OWNER',
        joinedAt: '2026-01-01T00:00:00Z',
      ),
      HomeMemberModel(
        id: 'mem-2',
        userId: 'u-2',
        fullName: 'Family Member',
        email: 'member@example.com',
        role: 'MEMBER',
        joinedAt: '2026-02-01T00:00:00Z',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncStateProvider.overrideWith((ref) => Stream.value(const SyncState(status: NetworkStatus.online))),
          homeControllerProvider.overrideWith(
            (ref) => MockHomeController(
              HomeState(homes: [testHome], activeHome: testHome),
            ),
          ),
          membersControllerProvider.overrideWith(
            (ref) => MockMembersController(
              MembersState(members: testMembers),
            ),
          ),
          authControllerProvider.overrideWith(
            (ref) => MockAuthController(
              AuthState(
                isAuthenticated: true,
                user: UserProfile(id: 'u-1', email: 'owner@example.com', fullName: 'Test Owner'),
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MembersScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Household Header
    expect(find.text('Test Family Household'), findsOneWidget);

    // Verify Invite Code Card
    expect(find.text('TEST1234'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('QR Code'), findsOneWidget);

    // Verify Member Cards
    expect(find.text('Test Owner'), findsOneWidget);
    expect(find.text('Family Member'), findsOneWidget);

    // Tap QR Code button to ensure dialog renders without layout exception
    await tester.tap(find.text('QR Code'));
    await tester.pumpAndSettle();

    expect(find.text('Household Invite Code'), findsOneWidget);
    expect(find.text('Copy Code'), findsOneWidget);

    // Close Dialog
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
  });
}
