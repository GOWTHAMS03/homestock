import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// ──────────────────────────────────────────────────
//  TABLE DEFINITIONS
// ──────────────────────────────────────────────────

/// Cached user profiles (current user and home members)
class LocalUsers extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get fullName => text()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached homes
class LocalHomes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get inviteCode => text()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get currentUserRole => text().withDefault(const Constant('MEMBER'))();
  IntColumn get memberCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached home memberships
class LocalHomeMembers extends Table {
  TextColumn get id => text()();
  TextColumn get homeId => text()();
  TextColumn get userId => text()();
  TextColumn get fullName => text()();
  TextColumn get email => text()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get role => text()();
  TextColumn get joinedAt => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached categories per home
class LocalCategories extends Table {
  TextColumn get id => text()();
  TextColumn get homeId => text()();
  TextColumn get name => text()();
  TextColumn get iconName => text().withDefault(const Constant('category'))();
  TextColumn get colorHex => text().withDefault(const Constant('#6366F1'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Core inventory items — full local copy
class LocalInventoryItems extends Table {
  TextColumn get id => text()();
  TextColumn get homeId => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get categoryName => text().withDefault(const Constant('General'))();
  TextColumn get categoryIcon => text().withDefault(const Constant('category'))();
  TextColumn get categoryColor => text().withDefault(const Constant('#6366F1'))();
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();
  RealColumn get quantity => real().withDefault(const Constant(0.0))();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  RealColumn get minimumQuantity => real().withDefault(const Constant(1.0))();
  RealColumn get maximumQuantity => real().nullable()();
  TextColumn get storageLocation => text().nullable()();
  RealColumn get purchasePrice => real().nullable()();
  TextColumn get purchaseDate => text().nullable()();
  TextColumn get expiryDate => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get stockStatus => text().withDefault(const Constant('IN_STOCK'))();
  TextColumn get expiryStatus => text().withDefault(const Constant('SAFE'))();
  IntColumn get daysUntilExpiry => integer().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  /// True if this item was created locally and hasn't been synced yet
  BoolColumn get isLocalOnly => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stock transaction audit trail
class LocalStockTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get inventoryItemId => text()();
  TextColumn get itemName => text().withDefault(const Constant(''))();
  TextColumn get userName => text().withDefault(const Constant(''))();
  TextColumn get transactionType => text()();
  RealColumn get quantityChange => real()();
  RealColumn get previousQuantity => real()();
  RealColumn get newQuantity => real()();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  TextColumn get reason => text().nullable()();
  TextColumn get createdAt => text()();
  BoolColumn get isLocalOnly => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Shopping list metadata
class LocalShoppingLists extends Table {
  TextColumn get id => text()();
  TextColumn get homeId => text()();
  TextColumn get name => text().withDefault(const Constant('Home Shopping List'))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Individual shopping list items
class LocalShoppingListItems extends Table {
  TextColumn get id => text()();
  TextColumn get shoppingListId => text()();
  TextColumn get inventoryItemId => text().nullable()();
  TextColumn get itemName => text()();
  TextColumn get categoryName => text().nullable()();
  TextColumn get categoryIcon => text().withDefault(const Constant('category'))();
  TextColumn get categoryColor => text().withDefault(const Constant('#6366F1'))();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isAutoGenerated => boolean().withDefault(const Constant(false))();
  TextColumn get addedByName => text().withDefault(const Constant(''))();
  TextColumn get completedByName => text().nullable()();
  TextColumn get completedAt => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isLocalOnly => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Store references
class LocalStores extends Table {
  TextColumn get id => text()();
  TextColumn get homeId => text()();
  TextColumn get name => text()();
  TextColumn get location => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Purchase records
class LocalPurchases extends Table {
  TextColumn get id => text()();
  TextColumn get homeId => text()();
  TextColumn get storeId => text().nullable()();
  TextColumn get storeName => text().nullable()();
  TextColumn get recordedByName => text().withDefault(const Constant(''))();
  TextColumn get purchaseDate => text()();
  RealColumn get totalAmount => real()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get receiptImageUrl => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isLocalOnly => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Purchase line items
class LocalPurchaseItems extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseId => text()();
  TextColumn get inventoryItemId => text().nullable()();
  TextColumn get itemName => text()();
  TextColumn get categoryName => text().nullable()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  RealColumn get unitPrice => real()();
  RealColumn get totalPrice => real()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached notifications
class LocalNotifications extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get message => text()();
  TextColumn get type => text().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sync queue — every offline mutation creates a row here
class SyncQueueEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationId => text()();
  TextColumn get operationType => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get payload => text()(); // JSON
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('PENDING'))(); // PENDING, SYNCING, SYNCED, FAILED, CONFLICT
  TextColumn get lastError => text().nullable()();
  TextColumn get homeId => text()();
}

/// Sync metadata — tracks last sync timestamp per home
class SyncMetadataEntries extends Table {
  TextColumn get homeId => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {homeId};
}

/// Cached product offers for smart shopping price comparison
class LocalProductOffers extends Table {
  TextColumn get id => text()();
  TextColumn get shoppingItemId => text()();
  TextColumn get provider => text()();
  TextColumn get productName => text()();
  TextColumn get brand => text().nullable()();
  RealColumn get price => real()();
  RealColumn get deliveryCharge => real().nullable()();
  RealColumn get effectivePrice => real()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get availability => text().nullable()();
  TextColumn get estimatedDelivery => text().nullable()();
  TextColumn get affiliateUrl => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  RealColumn get matchConfidence => real().nullable()();
  TextColumn get matchType => text().nullable()();
  TextColumn get pricePerUnitLabel => text().nullable()();
  DateTimeColumn get lastCheckedAt => dateTime().nullable()();
  DateTimeColumn get cachedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ──────────────────────────────────────────────────
//  DATABASE CLASS
// ──────────────────────────────────────────────────

@DriftDatabase(tables: [
  LocalUsers,
  LocalHomes,
  LocalHomeMembers,
  LocalCategories,
  LocalInventoryItems,
  LocalStockTransactions,
  LocalShoppingLists,
  LocalShoppingListItems,
  LocalStores,
  LocalPurchases,
  LocalPurchaseItems,
  LocalNotifications,
  SyncQueueEntries,
  SyncMetadataEntries,
  LocalProductOffers,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing — allows injecting a custom query executor
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(localProductOffers);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'homestock.sqlite'));
    if (kDebugMode) {
      print('[AppDatabase] Opening database at: ${file.path}');
    }
    return NativeDatabase.createInBackground(file);
  });
}
