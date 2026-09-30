import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/app_database.dart';

// Hide drift's isNull/isNotNull to avoid conflict with matcher.
// ignore: unused_import
import 'package:drift/drift.dart' hide isNull, isNotNull;

/// Creates an in-memory database for testing.
AppDatabase _createTestDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;

  setUp(() async {
    db = _createTestDb();
  });

  tearDown(() async {
    await db.close();
  });

  // ── Helpers ──────────────────────────────────────────────────────────

  Future<void> seedMaterial(String id, String barcode, String name, String category) async {
    await db.into(db.cachedMaterials).insert(
          CachedMaterialsCompanion.insert(
            id: id,
            barcode: barcode,
            name: name,
            category: category,
            packing: '750 ML',
            saleRate: 100,
            taxPercent: 18,
          ),
        );
  }

  Future<void> seedStock(String materialId, String barcode, String name, String category, int qty) async {
    await db.into(db.cachedInventoryStocks).insert(
          CachedInventoryStocksCompanion.insert(
            materialId: materialId,
            barcode: barcode,
            name: name,
            category: category,
            qtyOnHand: qty,
          ),
        );
  }

  Future<int?> readStockQty(String materialId) async {
    final row = await (db.select(db.cachedInventoryStocks)
          ..where((t) => t.materialId.equals(materialId)))
        .getSingleOrNull();
    return row?.qtyOnHand;
  }

  // ── Sale deduction ──────────────────────────────────────────────────

  group('Sale stock deduction', () {
    test('deducts from existing stock row', () async {
      await seedMaterial('SKU-1', 'BC-1', 'Test Whisky', 'Whisky');
      await seedStock('SKU-1', 'BC-1', 'Test Whisky', 'Whisky', 20);

      await db.transaction(() async {
        final stock = await (db.select(db.cachedInventoryStocks)
              ..where((t) => t.materialId.equals('SKU-1')))
            .getSingleOrNull();
        expect(stock, isNot(equals(null)));
        await (db.update(db.cachedInventoryStocks)
              ..where((t) => t.materialId.equals('SKU-1')))
            .write(CachedInventoryStocksCompanion(
          qtyOnHand: Value(stock!.qtyOnHand - 3),
        ));
      });

      expect(await readStockQty('SKU-1'), 17);
    });

    test('allows negative stock (no clamp)', () async {
      await seedMaterial('SKU-2', 'BC-2', 'Test Beer', 'Beer');
      await seedStock('SKU-2', 'BC-2', 'Test Beer', 'Beer', 2);

      await db.transaction(() async {
        final stock = await (db.select(db.cachedInventoryStocks)
              ..where((t) => t.materialId.equals('SKU-2')))
            .getSingleOrNull();
        await (db.update(db.cachedInventoryStocks)
              ..where((t) => t.materialId.equals('SKU-2')))
            .write(CachedInventoryStocksCompanion(
          qtyOnHand: Value(stock!.qtyOnHand - 5),
        ));
      });

      expect(await readStockQty('SKU-2'), -3);
    });

    test('upserts stock row when missing', () async {
      await seedMaterial('SKU-3', 'BC-3', 'Test Rum', 'Rum');

      await db.transaction(() async {
        final stock = await (db.select(db.cachedInventoryStocks)
              ..where((t) => t.materialId.equals('SKU-3')))
            .getSingleOrNull();
        expect(stock, equals(null));

        final material = await (db.select(db.cachedMaterials)
              ..where((t) => t.id.equals('SKU-3')))
            .getSingleOrNull();

        await db.into(db.cachedInventoryStocks).insert(
              CachedInventoryStocksCompanion.insert(
                materialId: 'SKU-3',
                barcode: material?.barcode ?? 'SKU-3',
                name: material?.name ?? 'SKU-3',
                category: material?.category ?? 'Unknown',
                qtyOnHand: -2,
              ),
              mode: InsertMode.insertOrReplace,
            );
      });

      expect(await readStockQty('SKU-3'), -2);
    });
  });

  // ── Sale return ─────────────────────────────────────────────────────

  group('Sale return stock restoration', () {
    test('adds quantity back on return', () async {
      await seedMaterial('SKU-4', 'BC-4', 'Test Wine', 'Wine');
      await seedStock('SKU-4', 'BC-4', 'Test Wine', 'Wine', 8);

      // Simulate sale: deduct 3
      await (db.update(db.cachedInventoryStocks)
            ..where((t) => t.materialId.equals('SKU-4')))
          .write(CachedInventoryStocksCompanion(qtyOnHand: const Value(5)));
      expect(await readStockQty('SKU-4'), 5);

      // Simulate return: add 3 back
      await db.transaction(() async {
        final stock = await (db.select(db.cachedInventoryStocks)
              ..where((t) => t.materialId.equals('SKU-4')))
            .getSingleOrNull();
        await (db.update(db.cachedInventoryStocks)
              ..where((t) => t.materialId.equals('SKU-4')))
            .write(CachedInventoryStocksCompanion(
          qtyOnHand: Value(stock!.qtyOnHand + 3),
        ));
      });

      expect(await readStockQty('SKU-4'), 8);
    });
  });

  // ── Purchase add ────────────────────────────────────────────────────

  group('Purchase stock addition', () {
    test('adds to existing stock row', () async {
      await seedMaterial('SKU-5', 'BC-5', 'Test Vodka', 'Vodka');
      await seedStock('SKU-5', 'BC-5', 'Test Vodka', 'Vodka', 10);

      await db.transaction(() async {
        final existing = await (db.select(db.cachedInventoryStocks)
              ..where((t) => t.materialId.equals('SKU-5')))
            .getSingleOrNull();

        await db.into(db.cachedInventoryStocks).insert(
              CachedInventoryStocksCompanion.insert(
                materialId: 'SKU-5',
                barcode: 'BC-5',
                name: 'Test Vodka',
                category: 'Vodka',
                qtyOnHand: (existing?.qtyOnHand ?? 0) + 6,
              ),
              mode: InsertMode.insertOrReplace,
            );
      });

      expect(await readStockQty('SKU-5'), 16);
    });

    test('creates stock row if missing', () async {
      await seedMaterial('SKU-6', 'BC-6', 'New Item', 'Whisky');

      await db.transaction(() async {
        final existing = await (db.select(db.cachedInventoryStocks)
              ..where((t) => t.materialId.equals('SKU-6')))
            .getSingleOrNull();

        await db.into(db.cachedInventoryStocks).insert(
              CachedInventoryStocksCompanion.insert(
                materialId: 'SKU-6',
                barcode: 'BC-6',
                name: 'New Item',
                category: 'Whisky',
                qtyOnHand: (existing?.qtyOnHand ?? 0) + 12,
              ),
              mode: InsertMode.insertOrReplace,
            );
      });

      expect(await readStockQty('SKU-6'), 12);
    });
  });

  // ── Purchase return ─────────────────────────────────────────────────

  group('Purchase return stock deduction', () {
    test('deducts on purchase return (allows negative)', () async {
      await seedMaterial('SKU-7', 'BC-7', 'Test Brandy', 'Brandy');
      await seedStock('SKU-7', 'BC-7', 'Test Brandy', 'Brandy', 3);

      await db.transaction(() async {
        final stock = await (db.select(db.cachedInventoryStocks)
              ..where((t) => t.materialId.equals('SKU-7')))
            .getSingleOrNull();
        await (db.update(db.cachedInventoryStocks)
              ..where((t) => t.materialId.equals('SKU-7')))
            .write(CachedInventoryStocksCompanion(
          qtyOnHand: Value(stock!.qtyOnHand - 5),
        ));
      });

      expect(await readStockQty('SKU-7'), -2);
    });
  });

  // ── Transaction rollback ────────────────────────────────────────────

  group('Transaction rollback', () {
    test('rolls back stock if a line fails mid-transaction', () async {
      await seedMaterial('SKU-8', 'BC-8', 'Rollback Test', 'Whisky');
      await seedStock('SKU-8', 'BC-8', 'Rollback Test', 'Whisky', 10);

      try {
        await db.transaction(() async {
          await (db.update(db.cachedInventoryStocks)
                ..where((t) => t.materialId.equals('SKU-8')))
              .write(CachedInventoryStocksCompanion(qtyOnHand: const Value(7)));

          throw Exception('Simulated line item failure');
        });
      } catch (_) {
        // Expected
      }

      expect(await readStockQty('SKU-8'), 10);
    });
  });
}
