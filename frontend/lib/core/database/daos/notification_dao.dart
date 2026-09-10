import 'package:drift/drift.dart';
import '../app_database.dart';

/// Data Access Object for cached notifications in SQLite.
/// Supports offline reading, unread count tracking, and local syncing.
class NotificationDao {
  final AppDatabase _db;

  NotificationDao(this._db);

  /// Fetch notifications ordered by creation date descending.
  Future<List<LocalNotification>> getNotifications({int limit = 50}) {
    return (_db.select(_db.localNotifications)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Watch notifications for real-time reactive UI updates.
  Stream<List<LocalNotification>> watchNotifications({int limit = 50}) {
    return (_db.select(_db.localNotifications)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }

  /// Count unread notifications.
  Future<int> getUnreadCount() async {
    final countExp = _db.localNotifications.id.count();
    final query = _db.selectOnly(_db.localNotifications)
      ..where(_db.localNotifications.isRead.equals(false))
      ..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  /// Watch unread notifications count.
  Stream<int> watchUnreadCount() {
    final countExp = _db.localNotifications.id.count();
    final query = _db.selectOnly(_db.localNotifications)
      ..where(_db.localNotifications.isRead.equals(false))
      ..addColumns([countExp]);
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  /// Upsert a single notification.
  Future<void> upsertNotification(LocalNotificationsCompanion notification) {
    return _db.into(_db.localNotifications).insertOnConflictUpdate(notification);
  }

  /// Batch upsert notifications from remote sync or local generation.
  Future<void> upsertNotifications(List<LocalNotificationsCompanion> notifications) {
    return _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.localNotifications, notifications);
    });
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String id) {
    return (_db.update(_db.localNotifications)..where((t) => t.id.equals(id)))
        .write(const LocalNotificationsCompanion(isRead: Value(true)));
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() {
    return (_db.update(_db.localNotifications)..where((t) => t.isRead.equals(false)))
        .write(const LocalNotificationsCompanion(isRead: Value(true)));
  }

  /// Delete a single notification by id.
  Future<int> deleteNotification(String id) {
    return (_db.delete(_db.localNotifications)..where((t) => t.id.equals(id))).go();
  }

  /// Delete read notifications older than [cutoff].
  Future<int> deleteReadOlderThan(DateTime cutoff) {
    return (_db.delete(_db.localNotifications)
          ..where((t) => t.isRead.equals(true) & t.createdAt.isSmallerThanValue(cutoff)))
        .go();
  }

  /// Clear all notifications.
  Future<int> clearAll() {
    return _db.delete(_db.localNotifications).go();
  }
}

