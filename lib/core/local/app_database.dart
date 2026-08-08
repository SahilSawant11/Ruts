import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class CachedMaterials extends Table {
  TextColumn get id => text()();
  TextColumn get barcode => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get packing => text()();
  RealColumn get saleRate => real()();
  RealColumn get taxPercent => real()();
  IntColumn get stockQty => integer().withDefault(const Constant(0))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedSuppliers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get address => text().nullable()();
  TextColumn get contactNo => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get vatNo => text().nullable()();
  TextColumn get bankDetails => text().nullable()();
  RealColumn get disPercent => real().withDefault(const Constant(0))();
  RealColumn get openingBalance => real().withDefault(const Constant(0))();
  TextColumn get balanceType => text().withDefault(const Constant('Credit'))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class CachedInventoryStocks extends Table {
  TextColumn get materialId => text()();
  TextColumn get barcode => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  IntColumn get qtyOnHand => integer()();
  IntColumn get reorderLevel => integer().withDefault(const Constant(10))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {materialId};
}

class CachedSalesBills extends Table {
  TextColumn get id => text()();
  TextColumn get billNo => text()();
  TextColumn get customerId => text().nullable()();
  TextColumn get payMode => text()();
  TextColumn get status => text()();
  RealColumn get totalAmount => real()();
  RealColumn get balanceDue => real()();
  RealColumn get totalTax => real()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  DateTimeColumn get billDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedSaleLineItems extends Table {
  TextColumn get id => text()();
  TextColumn get salesBillId => text()();
  TextColumn get materialId => text().nullable()();
  TextColumn get barcodeNo => text()();
  TextColumn get materialType => text()();
  TextColumn get materialName => text()();
  TextColumn get batchNo => text().nullable()();
  TextColumn get packing => text().nullable()();
  IntColumn get quantity => integer()();
  IntColumn get qtyCase => integer().withDefault(const Constant(0))();
  RealColumn get rate => real()();
  RealColumn get discountPercent => real()();
  RealColumn get discountAmount => real()();
  RealColumn get taxPercent => real()();
  RealColumn get taxAmount => real()();
  RealColumn get amount => real()();
  IntColumn get lineNumber => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [
  CachedMaterials,
  CachedSuppliers,
  SyncQueueItems,
  CachedInventoryStocks,
  CachedSalesBills,
  CachedSaleLineItems,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.defaults() : super(driftDatabase(name: 'pos_app.sqlite'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(syncQueueItems);
          }
          if (from < 3) {
            await m.createTable(cachedInventoryStocks);
          }
          if (from < 4) {
            await m.createTable(cachedSalesBills);
            await m.createTable(cachedSaleLineItems);
          }
        },
      );
}
