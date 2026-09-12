import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/storage/cache_service.dart';
import 'package:homestock/core/storage/secure_storage_service.dart';
import 'package:homestock/features/auth/auth_state.dart';

class FakeCacheService extends CacheService {
  final Map<String, dynamic> _data = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> set(String key, dynamic value) async {
    _data[key] = value;
  }

  @override
  dynamic get(String key) => _data[key];

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }
}

void main() {
  group('Auth State Machine Tests', () {
    test('AuthState defaults to initializing', () {
      const state = AuthState();
      expect(state.status, equals(AuthStatus.initializing));
      expect(state.isAuthenticated, isFalse);
      expect(state.isUserNotFound, isFalse);
      expect(state.isAccountDisabled, isFalse);
      expect(state.isSessionExpired, isFalse);
      expect(state.isMembershipRemoved, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.user, isNull);
    });

    test('AuthState transitions to authenticated when authenticated', () {
      final user = UserProfile(
        id: 'u-1',
        email: 'test@homestock.app',
        fullName: 'Test User',
        username: 'testuser',
        status: 'ACTIVE',
      );
      final state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
      expect(state.status, equals(AuthStatus.authenticated));
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.username, equals('testuser'));
    });

    test('AuthState transitions to userNotFound with verification notice', () {
      const notice = "We couldn't verify your HomeStock account.\n\nYour account may have been removed or your session is no longer valid.\n\nPlease sign in again to continue.";
      const state = AuthState(
        status: AuthStatus.userNotFound,
        verificationNotice: notice,
      );
      expect(state.status, equals(AuthStatus.userNotFound));
      expect(state.isAuthenticated, isFalse);
      expect(state.isUserNotFound, isTrue);
      expect(state.verificationNotice, equals(notice));
    });

    test('AuthState transitions to accountDisabled', () {
      const state = AuthState(
        status: AuthStatus.accountDisabled,
        verificationNotice: "This HomeStock account is disabled. Please contact support.",
      );
      expect(state.status, equals(AuthStatus.accountDisabled));
      expect(state.isAuthenticated, isFalse);
      expect(state.isAccountDisabled, isTrue);
    });

    test('AuthState transitions to sessionExpired', () {
      const state = AuthState(
        status: AuthStatus.sessionExpired,
        verificationNotice: "Your session has expired. Please sign in again.",
      );
      expect(state.status, equals(AuthStatus.sessionExpired));
      expect(state.isAuthenticated, isFalse);
      expect(state.isSessionExpired, isTrue);
    });

    test('AuthState transitions to membershipRemoved with activeRoomId', () {
      const state = AuthState(
        status: AuthStatus.membershipRemoved,
        activeRoomId: 'room-100',
        verificationNotice: "You are no longer an active member of this household.",
      );
      expect(state.status, equals(AuthStatus.membershipRemoved));
      expect(state.isAuthenticated, isFalse);
      expect(state.isMembershipRemoved, isTrue);
      expect(state.activeRoomId, equals('room-100'));
    });

    test('UserProfile JSON serialization supports username and status', () {
      final user = UserProfile(
        id: 'u-123',
        email: 'alice@example.com',
        fullName: 'Alice Smith',
        displayName: 'Alice S',
        username: 'alicesmith',
        status: 'ACTIVE',
      );

      final json = user.toJson();
      expect(json['id'], equals('u-123'));
      expect(json['username'], equals('alicesmith'));
      expect(json['displayName'], equals('Alice S'));
      expect(json['status'], equals('ACTIVE'));

      final fromJson = UserProfile.fromJson(json);
      expect(fromJson.id, equals('u-123'));
      expect(fromJson.username, equals('alicesmith'));
      expect(fromJson.displayName, equals('Alice S'));
      expect(fromJson.status, equals('ACTIVE'));
    });

    test('SecureStorageService clearAll removes tokens without affecting local SQLite', () async {
      final cache = FakeCacheService();
      final storage = SecureStorageService(cacheService: cache);

      await storage.saveTokens(accessToken: 'token-a', refreshToken: 'token-b');
      await storage.saveUser(UserProfile(id: '1', email: 'a@b.com', fullName: 'A B'));

      expect(storage.hasCachedTokensSync(), isTrue);

      await storage.clearAll();

      expect(storage.hasCachedTokensSync(), isFalse);
      expect(storage.getCachedUserSync(), isNull);
    });
  });
}
