import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:pos_app/core/auth/password_hasher.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/core/local/db_paths.dart';
import 'package:pos_app/features/masters/data/local_masters_repository.dart';
import 'package:pos_app/features/masters/data/masters_api_repository.dart';
import 'package:pos_app/features/purchase/data/local_purchase_repository.dart';
import 'package:pos_app/features/purchase/data/purchase_api_repository.dart';
import 'package:pos_app/features/sales/data/local_sales_repository.dart';
import 'package:pos_app/features/sales/data/models/create_sale_request.dart';
import 'package:pos_app/features/sales/data/sales_api_repository.dart';

/// A throwaway Caskly install: temp root folder + file-backed database.
class TestEnv {
  TestEnv._(this.root, this.db);

  final Directory root;
  final AppDatabase db;

  late final masters = LocalMastersRepository(db, MastersApiRepository(http.Client()));
  late final sales = LocalSalesRepository(db, SalesApiRepository(http.Client()), masters);
  late final purchases = LocalPurchaseRepository(db, PurchaseApiRepository(http.Client()), masters);

  static Future<TestEnv> create({bool fileBacked = true}) async {
    PasswordHasher.iterations = 1000; // keep tests fast; format stores the count
    final root = await Directory.systemTemp.createTemp('caskly_test_');
    DbPaths.rootOverride = root;
    final AppDatabase db;
    if (fileBacked) {
      final path = await DbPaths.prepareDatabaseFile();
      db = AppDatabase(NativeDatabase(File(path)));
    } else {
      db = AppDatabase(NativeDatabase.memory());
    }
    return TestEnv._(root, db);
  }

  Future<void> dispose() async {
    await db.close();
    DbPaths.rootOverride = null;
    if (await root.exists()) await root.delete(recursive: true);
  }

  Future<void> addMaterial(String id, {int stock = 100, double rate = 100}) async {
    await db.into(db.cachedMaterials).insert(CachedMaterialsCompanion.insert(
          id: id,
          barcode: 'BC-$id',
          name: 'Item $id',
          category: 'Whisky',
          packing: '750 ML',
          saleRate: rate,
          taxPercent: 0,
          stockQty: Value(stock),
        ));
    await db.into(db.cachedInventoryStocks).insert(CachedInventoryStocksCompanion.insert(
          materialId: id,
          barcode: 'BC-$id',
          name: 'Item $id',
          category: 'Whisky',
          qtyOnHand: stock,
        ));
  }

  Future<int> stockOf(String id) async =>
      (await (db.select(db.cachedInventoryStocks)..where((t) => t.materialId.equals(id))).getSingle()).qtyOnHand;

  static CreateSaleRequest sale(Map<String, int> qtyById, {double rate = 100, String payMode = 'Cash'}) {
    final lines = [
      for (final e in qtyById.entries)
        CreateSaleLineItemRequest(
          materialId: e.key,
          barcodeNo: 'BC-${e.key}',
          materialType: 'Whisky',
          materialName: 'Item ${e.key}',
          batchNo: null,
          packing: '750 ML',
          quantity: e.value,
          qtyCase: 0,
          rate: rate,
          discountPercent: 0,
          discountAmount: 0,
          taxPercent: 0,
          taxAmount: 0,
          amount: rate * e.value,
        ),
    ];
    final total = lines.fold<double>(0, (s, l) => s + l.amount);
    return CreateSaleRequest(
      billNo: 'ignored',
      payMode: payMode,
      taxableValue: total,
      totalDiscount: 0,
      totalTax: 0,
      totalAmount: total,
      balanceDue: total,
      lineItems: lines,
    );
  }
}
