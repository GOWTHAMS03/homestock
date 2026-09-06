import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/storage/cache_service.dart';
import 'package:homestock/core/storage/secure_storage_service.dart';
import 'package:homestock/features/auth/auth_state.dart';
import 'package:homestock/features/home_switcher/home_model.dart';

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
  group('Session Persistence & Serialization Tests', () {
    test('UserProfile round-trip JSON serialization', () {
      final user = UserProfile(
        id: 'user-123',
        email: 'test@homestock.app',
        fullName: 'Jane Doe',
        phoneNumber: '+1234567890',
        avatarUrl: 'https://example.com/avatar.png',
      );

      final json = user.toJson();
      expect(json['id'], equals('user-123'));
      expect(json['email'], equals('test@homestock.app'));
      expect(json['fullName'], equals('Jane Doe'));
      expect(json['phoneNumber'], equals('+1234567890'));

      final reconstructed = UserProfile.fromJson(json);
      expect(reconstructed.id, equals(user.id));
      expect(reconstructed.email, equals(user.email));
      expect(reconstructed.fullName, equals(user.fullName));
      expect(reconstructed.phoneNumber, equals(user.phoneNumber));
    });

    test('HomeModel round-trip JSON serialization', () {
      final home = HomeModel(
        id: 'home-456',
        name: 'Sweet Home',
        inviteCode: 'HS-9876',
        currentUserRole: 'OWNER',
        memberCount: 3,
      );

      final json = home.toJson();
      expect(json['id'], equals('home-456'));
      expect(json['name'], equals('Sweet Home'));
      expect(json['inviteCode'], equals('HS-9876'));
      expect(json['currentUserRole'], equals('OWNER'));
      expect(json['memberCount'], equals(3));

      final reconstructed = HomeModel.fromJson(json);
      expect(reconstructed.id, equals(home.id));
      expect(reconstructed.name, equals(home.name));
      expect(reconstructed.inviteCode, equals(home.inviteCode));
      expect(reconstructed.isOwner, isTrue);
      expect(reconstructed.isAdmin, isTrue);
    });

    test('SecureStorageService synchronous cache read and token detection', () async {
      final fakeCache = FakeCacheService();
      final storage = SecureStorageService(cacheService: fakeCache);

      expect(storage.hasCachedTokensSync(), isFalse);
      expect(storage.getCachedUserSync(), isNull);

      final user = UserProfile(
        id: 'u-1',
        email: 'user@test.com',
        fullName: 'John Smith',
      );

      await storage.saveTokens(accessToken: 'access-123', refreshToken: 'refresh-456');
      await storage.saveUser(user);

      expect(storage.hasCachedTokensSync(), isTrue);
      final cachedUser = storage.getCachedUserSync();
      expect(cachedUser, isNotNull);
      expect(cachedUser!.email, equals('user@test.com'));
      expect(cachedUser.fullName, equals('John Smith'));

      final asyncUser = await storage.getUser();
      expect(asyncUser?.id, equals('u-1'));
    });

    test('SecureStorageService preserves baseUrl on clearAll logout', () async {
      final fakeCache = FakeCacheService();
      final storage = SecureStorageService(cacheService: fakeCache);

      await storage.saveBaseUrl('http://192.168.1.50:8080/api/v1');
      await storage.saveTokens(accessToken: 'tok', refreshToken: 'ref');
      await storage.saveUser(UserProfile(id: 'u-2', email: 'u2@test.com', fullName: 'User Two'));

      expect(await storage.getBaseUrl(), equals('http://192.168.1.50:8080/api/v1'));
      expect(storage.hasCachedTokensSync(), isTrue);

      await storage.clearAll();

      // Tokens and user are purged
      expect(storage.hasCachedTokensSync(), isFalse);
      expect(storage.getCachedUserSync(), isNull);

      // Custom base URL is preserved for developer & LAN convenience
      expect(await storage.getBaseUrl(), equals('http://192.168.1.50:8080/api/v1'));
    });

    test('SecureStorageService caches homes for offline resumption', () async {
      final fakeCache = FakeCacheService();
      final storage = SecureStorageService(cacheService: fakeCache);

      final homes = [
        HomeModel(id: 'h-1', name: 'Main House', inviteCode: 'C1', currentUserRole: 'OWNER', memberCount: 2),
        HomeModel(id: 'h-2', name: 'Cabin', inviteCode: 'C2', currentUserRole: 'MEMBER', memberCount: 1),
      ];

      await storage.saveHomes(homes);

      final cachedHomes = storage.getCachedHomesSync();
      expect(cachedHomes, isNotNull);
      expect(cachedHomes!.length, equals(2));
      expect(cachedHomes[0].name, equals('Main House'));
      expect(cachedHomes[1].name, equals('Cabin'));
    });
  });
}
