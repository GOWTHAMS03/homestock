import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/database/app_database.dart';
import 'package:homestock/features/home_switcher/home_model.dart';

void main() {
  group('HomeModel & HomeMemberModel', () {
    test('HomeModel parses createdAt and roles properly', () {
      final json = {
        'id': 'home-123',
        'name': 'Green Villa',
        'inviteCode': 'GV7890AB',
        'currentUserRole': 'OWNER',
        'memberCount': 3,
        'createdAt': '2026-01-15T10:30:00.000Z',
      };

      final home = HomeModel.fromJson(json);
      expect(home.id, 'home-123');
      expect(home.name, 'Green Villa');
      expect(home.inviteCode, 'GV7890AB');
      expect(home.isOwner, isTrue);
      expect(home.isAdmin, isTrue);
      expect(home.memberCount, 3);
      expect(home.createdAt, '2026-01-15T10:30:00.000Z');

      final serialized = home.toJson();
      expect(serialized['createdAt'], '2026-01-15T10:30:00.000Z');
      expect(serialized['name'], 'Green Villa');
    });

    test('HomeMemberModel role getters work accurately', () {
      final ownerMember = HomeMemberModel(
        id: 'mem-1',
        userId: 'user-1',
        fullName: 'Alice Smith',
        email: 'alice@example.com',
        role: 'OWNER',
        joinedAt: '2026-01-10T12:00:00Z',
      );

      final adminMember = HomeMemberModel(
        id: 'mem-2',
        userId: 'user-2',
        fullName: 'Bob Smith',
        email: 'bob@example.com',
        role: 'ADMIN',
        joinedAt: '2026-01-12T12:00:00Z',
      );

      final regularMember = HomeMemberModel(
        id: 'mem-3',
        userId: 'user-3',
        fullName: 'Charlie Smith',
        email: 'charlie@example.com',
        role: 'MEMBER',
        joinedAt: '2026-01-14T12:00:00Z',
      );

      expect(ownerMember.isOwner, isTrue);
      expect(ownerMember.isAdmin, isFalse);
      expect(ownerMember.isMember, isFalse);

      expect(adminMember.isOwner, isFalse);
      expect(adminMember.isAdmin, isTrue);
      expect(adminMember.isMember, isFalse);

      expect(regularMember.isOwner, isFalse);
      expect(regularMember.isAdmin, isFalse);
      expect(regularMember.isMember, isTrue);

      // JSON serialization & deserialization
      final memberJson = regularMember.toJson();
      final reconstructed = HomeMemberModel.fromJson(memberJson);
      expect(reconstructed.id, regularMember.id);
      expect(reconstructed.fullName, 'Charlie Smith');
      expect(reconstructed.role, 'MEMBER');
    });
  });

  group('Offline LocalHomeMembers Database Caching', () {
    late AppDatabase db;
    const testHomeId = 'home-family-test-999';

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Drift saves and reads cached family members locally', () async {
      // 1. Insert two members locally
      await db.into(db.localHomeMembers).insert(
            LocalHomeMembersCompanion.insert(
              id: 'local-mem-1',
              homeId: testHomeId,
              userId: 'u-1',
              fullName: 'Gowtham',
              email: 'gowtham@example.com',
              role: 'OWNER',
              joinedAt: const drift.Value('2026-01-01T00:00:00Z'),
            ),
          );

      await db.into(db.localHomeMembers).insert(
            LocalHomeMembersCompanion.insert(
              id: 'local-mem-2',
              homeId: testHomeId,
              userId: 'u-2',
              fullName: 'Elena',
              email: 'elena@example.com',
              role: 'MEMBER',
              joinedAt: const drift.Value('2026-02-01T00:00:00Z'),
            ),
          );

      // 2. Query members for this home
      final rows = await (db.select(db.localHomeMembers)
            ..where((t) => t.homeId.equals(testHomeId)))
          .get();

      expect(rows.length, 2);
      expect(rows.map((r) => r.fullName), containsAll(['Gowtham', 'Elena']));

      // 3. Update member role locally
      await (db.update(db.localHomeMembers)
            ..where((t) => t.homeId.equals(testHomeId) & t.userId.equals('u-2')))
          .write(const LocalHomeMembersCompanion(role: drift.Value('ADMIN')));

      final updatedRow = await (db.select(db.localHomeMembers)
            ..where((t) => t.homeId.equals(testHomeId) & t.userId.equals('u-2')))
          .getSingle();
      expect(updatedRow.role, 'ADMIN');

      // 4. Remove member locally
      await (db.delete(db.localHomeMembers)
            ..where((t) => t.homeId.equals(testHomeId) & t.userId.equals('u-2')))
          .go();

      final remainingRows = await (db.select(db.localHomeMembers)
            ..where((t) => t.homeId.equals(testHomeId)))
          .get();
      expect(remainingRows.length, 1);
      expect(remainingRows.first.fullName, 'Gowtham');
    });
  });
}
