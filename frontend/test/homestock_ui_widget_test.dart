import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/network/api_client.dart';
import 'package:homestock/core/storage/secure_storage_service.dart';
import 'package:homestock/core/theme/app_theme.dart';
import 'package:homestock/features/auth/auth_controller.dart';
import 'package:homestock/features/auth/auth_state.dart';
import 'package:homestock/features/home_switcher/home_controller.dart';
import 'package:homestock/features/home_switcher/home_model.dart';
import 'package:homestock/features/home_switcher/home_repository.dart';
import 'package:homestock/features/profile/profile_screen.dart';

class MockHomeRepo extends HomeRepository {
  MockHomeRepo()
      : super(
          apiClient: ApiClient(secureStorage: SecureStorageService()),
          storage: SecureStorageService(),
        );

  @override
  Future<List<HomeMemberModel>> getMembers(String homeId) async => [];
}

class MockHomeController extends HomeController {
  MockHomeController(HomeState initial)
      : super(MockHomeRepo(), SecureStorageService()) {
    state = initial;
  }

  @override
  Future<void> loadHomes() async {}
}

class MockAuthController extends StateNotifier<AuthState>
    implements AuthController {
  MockAuthController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
      'ProfileScreen renders cleanly with HomeStock aesthetic, quick-action cards, and grouped lists',
      (WidgetTester tester) async {
    final testHome = HomeModel(
      id: 'home-123',
      name: 'Gowtham Home',
      inviteCode: 'HOME123',
      currentUserRole: 'OWNER',
      memberCount: 3,
      createdAt: '2026-09-01T00:00:00Z',
    );

    final mockHomeCtrl = MockHomeController(
      HomeState(
        homes: [testHome],
        activeHome: testHome,
        isLoading: false,
      ),
    );

    final mockAuthCtrl = MockAuthController(
      AuthState(
        isAuthenticated: true,
        user: UserProfile(
          id: 'user-001',
          fullName: 'Gowtham Sekar',
          phoneNumber: '+91 93455 33912',
          email: 'gowtham@example.com',
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeControllerProvider.overrideWith((ref) => mockHomeCtrl),
          authControllerProvider.overrideWith((ref) => mockAuthCtrl),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify user profile header
    expect(find.text('Gowtham Sekar'), findsOneWidget);
    expect(find.text('+91 93455 33912'), findsOneWidget);

    // Verify 3-card quick-action row
    expect(find.text('Your\nPurchases'), findsOneWidget);
    expect(find.text('Family\nMembers'), findsOneWidget);
    expect(find.text('Shopping\nList'), findsOneWidget);

    // Verify sync update banner
    expect(find.text('Inventory Sync Active'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);

    // Verify section titles
    expect(find.text('Household & Home'), findsOneWidget);
    expect(find.text('Your Information'), findsOneWidget);

    // Verify list items
    expect(find.text('Purchase History & Bills'), findsOneWidget);
    expect(find.text('Shared Shopping List'), findsOneWidget);
    expect(find.text('Family Members & Roles'), findsOneWidget);
    expect(find.text('Home Invite Code'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);

    // Verify circular back button icon is present
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
  });
}
