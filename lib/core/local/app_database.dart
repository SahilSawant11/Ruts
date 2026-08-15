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

  Future<void> ensureStarterData() async {
    final hasMaterials = await _tableHasRows('cached_materials');
    final hasSuppliers = await _tableHasRows('cached_suppliers');
    final hasInventory = await _tableHasRows('cached_inventory_stocks');
    final hasSalesBills = await _tableHasRows('cached_sales_bills');
    final hasSaleLines = await _tableHasRows('cached_sale_line_items');

    if (hasMaterials && hasSuppliers && hasInventory && hasSalesBills && hasSaleLines) {
      return;
    }

    final now = DateTime.now().toUtc();

    await transaction(() async {
      if (!hasSuppliers) {
        await batch((batch) {
          for (final supplier in _starterSuppliers) {
            batch.insert(
              cachedSuppliers,
              CachedSuppliersCompanion.insert(
                id: supplier.id,
                name: supplier.name,
                address: Value(supplier.address),
                contactNo: Value(supplier.contactNo),
                email: Value(supplier.email),
                vatNo: Value(supplier.vatNo),
                bankDetails: Value(supplier.bankDetails),
                disPercent: Value(supplier.disPercent),
                openingBalance: Value(supplier.openingBalance),
                balanceType: Value(supplier.balanceType),
                createdAt: Value(now),
                updatedAt: Value(now),
                lastSyncedAt: Value(now),
              ),
              mode: InsertMode.insertOrIgnore,
            );
          }
        });
      }

      if (!hasMaterials) {
        await batch((batch) {
          for (final material in _starterMaterials) {
            batch.insert(
              cachedMaterials,
              CachedMaterialsCompanion.insert(
                id: material.id,
                barcode: material.barcode,
                name: material.name,
                category: material.category,
                packing: material.packing,
                saleRate: material.saleRate,
                taxPercent: material.taxPercent,
                stockQty: Value(material.stockQty),
                createdAt: Value(now),
                updatedAt: Value(now),
                lastSyncedAt: Value(now),
              ),
              mode: InsertMode.insertOrIgnore,
            );
          }
        });
      }

      if (!hasInventory) {
        await batch((batch) {
          for (final stock in _starterInventory) {
            batch.insert(
              cachedInventoryStocks,
              CachedInventoryStocksCompanion.insert(
                materialId: stock.materialId,
                barcode: stock.barcode,
                name: stock.name,
                category: stock.category,
                qtyOnHand: stock.qtyOnHand,
                reorderLevel: Value(stock.reorderLevel),
                updatedAt: Value(now),
              ),
              mode: InsertMode.insertOrIgnore,
            );
          }
        });
      }

      if (!hasSalesBills || !hasSaleLines) {
        final seed = _buildStarterSalesHistory(now);
        await delete(cachedSaleLineItems).go();
        await delete(cachedSalesBills).go();

        await batch((batch) {
          for (final bill in seed.bills) {
            batch.insert(
              cachedSalesBills,
              CachedSalesBillsCompanion.insert(
                id: bill.id,
                billNo: bill.billNo,
                customerId: Value(bill.customerId),
                payMode: bill.payMode,
                status: bill.status,
                totalAmount: bill.totalAmount,
                balanceDue: bill.balanceDue,
                totalTax: bill.totalTax,
                syncStatus: const Value('synced'),
                billDate: bill.billDate,
                createdAt: Value(bill.createdAt),
                updatedAt: Value(bill.updatedAt),
              ),
            );
          }

          for (final line in seed.lines) {
            batch.insert(
              cachedSaleLineItems,
              CachedSaleLineItemsCompanion.insert(
                id: line.id,
                salesBillId: line.salesBillId,
                materialId: Value(line.materialId),
                barcodeNo: line.barcodeNo,
                materialType: line.materialType,
                materialName: line.materialName,
                batchNo: Value(line.batchNo),
                packing: Value(line.packing),
                quantity: line.quantity,
                qtyCase: Value(line.qtyCase),
                rate: line.rate,
                discountPercent: line.discountPercent,
                discountAmount: line.discountAmount,
                taxPercent: line.taxPercent,
                taxAmount: line.taxAmount,
                amount: line.amount,
                lineNumber: line.lineNumber,
              ),
            );
          }
        });
      }
    });
  }

  Future<bool> _tableHasRows(String tableName) async {
    final result = await customSelect(
      'SELECT EXISTS(SELECT 1 FROM $tableName LIMIT 1) AS present',
    ).getSingle();
    return result.read<int>('present') == 1;
  }
}

class _StarterSupplier {
  const _StarterSupplier({
    required this.id,
    required this.name,
    required this.address,
    required this.contactNo,
    required this.email,
    required this.vatNo,
    required this.bankDetails,
    required this.disPercent,
    required this.openingBalance,
    required this.balanceType,
  });

  final String id;
  final String name;
  final String address;
  final String contactNo;
  final String email;
  final String vatNo;
  final String bankDetails;
  final double disPercent;
  final double openingBalance;
  final String balanceType;
}

class _StarterMaterial {
  const _StarterMaterial({
    required this.id,
    required this.barcode,
    required this.name,
    required this.category,
    required this.packing,
    required this.saleRate,
    required this.taxPercent,
    required this.stockQty,
  });

  final String id;
  final String barcode;
  final String name;
  final String category;
  final String packing;
  final double saleRate;
  final double taxPercent;
  final int stockQty;
}

class _StarterInventoryStock {
  const _StarterInventoryStock({
    required this.materialId,
    required this.barcode,
    required this.name,
    required this.category,
    required this.qtyOnHand,
    required this.reorderLevel,
  });

  final String materialId;
  final String barcode;
  final String name;
  final String category;
  final int qtyOnHand;
  final int reorderLevel;
}

class _StarterSeedBundle {
  const _StarterSeedBundle({
    required this.bills,
    required this.lines,
  });

  final List<_StarterSalesBill> bills;
  final List<_StarterSalesLine> lines;
}

class _StarterSalesBill {
  const _StarterSalesBill({
    required this.id,
    required this.billNo,
    required this.customerId,
    required this.payMode,
    required this.status,
    required this.totalAmount,
    required this.balanceDue,
    required this.totalTax,
    required this.billDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String billNo;
  final String? customerId;
  final String payMode;
  final String status;
  final double totalAmount;
  final double balanceDue;
  final double totalTax;
  final DateTime billDate;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class _StarterSalesLine {
  const _StarterSalesLine({
    required this.id,
    required this.salesBillId,
    required this.materialId,
    required this.barcodeNo,
    required this.materialType,
    required this.materialName,
    required this.batchNo,
    required this.packing,
    required this.quantity,
    required this.qtyCase,
    required this.rate,
    required this.discountPercent,
    required this.discountAmount,
    required this.taxPercent,
    required this.taxAmount,
    required this.amount,
    required this.lineNumber,
  });

  final String id;
  final String salesBillId;
  final String materialId;
  final String barcodeNo;
  final String materialType;
  final String materialName;
  final String? batchNo;
  final String? packing;
  final int quantity;
  final int qtyCase;
  final double rate;
  final double discountPercent;
  final double discountAmount;
  final double taxPercent;
  final double taxAmount;
  final double amount;
  final int lineNumber;
}

_StarterSeedBundle _buildStarterSalesHistory(DateTime now) {
  final bills = <_StarterSalesBill>[];
  final lines = <_StarterSalesLine>[];
  final saleDate = DateTime.utc(now.year, now.month, now.day);
  var billSequence = 1;

  for (var dayIndex = 89; dayIndex >= 0; dayIndex--) {
    final day = saleDate.subtract(Duration(days: dayIndex));
    final weekendBonus = day.weekday == DateTime.friday || day.weekday == DateTime.saturday ? 1 : 0;
    final billCount = 1 + ((89 - dayIndex) % 3) + weekendBonus;

    for (var billOffset = 0; billOffset < billCount; billOffset++) {
      final billId = 'seed-sale-${day.millisecondsSinceEpoch}-$billOffset';
      final billNo =
          'CSK${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}-${billSequence.toString().padLeft(4, '0')}';
      final createdAt = DateTime.utc(
        day.year,
        day.month,
        day.day,
        11 + (billOffset % 7),
        (billOffset * 13) % 60,
      );
      final payModes = ['Cash', 'UPI', 'Card', 'Credit'];
      final payMode = payModes[(dayIndex + billOffset) % payModes.length];
      final customerId = payMode == 'Credit' ? 'CUST-${((89 - dayIndex) % 6) + 1}' : null;
      final status = payMode == 'Credit' ? 'partial' : 'paid';

      final lineCount = 2 + ((dayIndex + billOffset) % 3);
      var totalAmount = 0.0;
      var totalTax = 0.0;

      for (var lineIndex = 0; lineIndex < lineCount; lineIndex++) {
        final material = _starterMaterials[((89 - dayIndex) * 3 + (billOffset * 5) + lineIndex) % _starterMaterials.length];
        final isCaseHeavy = material.category == 'Beer' && ((dayIndex + lineIndex) % 4 == 0);
        final qtyCase = isCaseHeavy ? 1 : 0;
        final quantity = 1 + ((dayIndex + billOffset + lineIndex) % 5);
        final grossUnits = quantity + (qtyCase * 12);
        final gross = material.saleRate * grossUnits;
        final discountPercent = ((dayIndex + lineIndex + billOffset) % 5 == 0) ? 5.0 : 0.0;
        final discountAmount = gross * (discountPercent / 100);
        final taxable = gross - discountAmount;
        final taxAmount = taxable * (material.taxPercent / 100);
        final amount = taxable + taxAmount;
        totalAmount += amount;
        totalTax += taxAmount;

        lines.add(
          _StarterSalesLine(
            id: '$billId-line-${lineIndex + 1}',
            salesBillId: billId,
            materialId: material.id,
            barcodeNo: material.barcode,
            materialType: material.category,
            materialName: material.name,
            batchNo: 'B-${day.month.toString().padLeft(2, '0')}${lineIndex + 1}',
            packing: material.packing,
            quantity: quantity,
            qtyCase: qtyCase,
            rate: material.saleRate,
            discountPercent: discountPercent,
            discountAmount: double.parse(discountAmount.toStringAsFixed(2)),
            taxPercent: material.taxPercent,
            taxAmount: double.parse(taxAmount.toStringAsFixed(2)),
            amount: double.parse(amount.toStringAsFixed(2)),
            lineNumber: lineIndex + 1,
          ),
        );
      }

      final roundedTotal = double.parse(totalAmount.toStringAsFixed(2));
      final roundedTax = double.parse(totalTax.toStringAsFixed(2));
      final balanceDue = payMode == 'Credit'
          ? double.parse((roundedTotal * 0.35).toStringAsFixed(2))
          : 0.0;

      bills.add(
        _StarterSalesBill(
          id: billId,
          billNo: billNo,
          customerId: customerId,
          payMode: payMode,
          status: status,
          totalAmount: roundedTotal,
          balanceDue: balanceDue,
          totalTax: roundedTax,
          billDate: day,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );

      billSequence += 1;
    }
  }

  return _StarterSeedBundle(bills: bills, lines: lines);
}

const _starterSuppliers = <_StarterSupplier>[
  _StarterSupplier(
    id: 'SUP-001',
    name: 'Royal Spirits Distributors',
    address: 'Panaji, Goa',
    contactNo: '9876543210',
    email: 'orders@royalspirits.test',
    vatNo: 'VAT-GOA-001',
    bankDetails: 'HDFC • 102233445566',
    disPercent: 3,
    openingBalance: 0,
    balanceType: 'Credit',
  ),
  _StarterSupplier(
    id: 'SUP-002',
    name: 'Sunset Beverage Co.',
    address: 'Mapusa, Goa',
    contactNo: '9822001122',
    email: 'trade@sunsetbev.test',
    vatNo: 'VAT-GOA-002',
    bankDetails: 'ICICI • 882211004455',
    disPercent: 2,
    openingBalance: 0,
    balanceType: 'Credit',
  ),
  _StarterSupplier(
    id: 'SUP-003',
    name: 'Cask & Barrel Wholesale',
    address: 'Margao, Goa',
    contactNo: '9811007788',
    email: 'hello@caskbarrel.test',
    vatNo: 'VAT-GOA-003',
    bankDetails: 'Axis • 556677889900',
    disPercent: 2.5,
    openingBalance: 0,
    balanceType: 'Credit',
  ),
];

const _starterMaterials = <_StarterMaterial>[
  _StarterMaterial(
    id: 'SKU-1001',
    barcode: '8901001000011',
    name: 'Royal Stag Whisky',
    category: 'Whisky',
    packing: '750 ML',
    saleRate: 980,
    taxPercent: 18,
    stockQty: 24,
  ),
  _StarterMaterial(
    id: 'SKU-1002',
    barcode: '8901001000028',
    name: 'Blenders Pride Whisky',
    category: 'Whisky',
    packing: '750 ML',
    saleRate: 1290,
    taxPercent: 18,
    stockQty: 18,
  ),
  _StarterMaterial(
    id: 'SKU-1003',
    barcode: '8901001000035',
    name: 'Kingfisher Premium',
    category: 'Beer',
    packing: '650 ML',
    saleRate: 160,
    taxPercent: 12,
    stockQty: 48,
  ),
  _StarterMaterial(
    id: 'SKU-1004',
    barcode: '8901001000042',
    name: 'Bira White',
    category: 'Beer',
    packing: '330 ML',
    saleRate: 140,
    taxPercent: 12,
    stockQty: 36,
  ),
  _StarterMaterial(
    id: 'SKU-1005',
    barcode: '8901001000059',
    name: 'Sula Red Wine',
    category: 'Wine',
    packing: '750 ML',
    saleRate: 1100,
    taxPercent: 18,
    stockQty: 12,
  ),
  _StarterMaterial(
    id: 'SKU-1006',
    barcode: '8901001000066',
    name: 'Bacardi White Rum',
    category: 'Rum',
    packing: '750 ML',
    saleRate: 1180,
    taxPercent: 18,
    stockQty: 16,
  ),
  _StarterMaterial(
    id: 'SKU-1007',
    barcode: '8901001000073',
    name: 'Magic Moments Vodka',
    category: 'Vodka',
    packing: '750 ML',
    saleRate: 950,
    taxPercent: 18,
    stockQty: 14,
  ),
  _StarterMaterial(
    id: 'SKU-1008',
    barcode: '8901001000080',
    name: 'Coca-Cola Can',
    category: 'Soft Drink',
    packing: '300 ML',
    saleRate: 40,
    taxPercent: 5,
    stockQty: 60,
  ),
];

const _starterInventory = <_StarterInventoryStock>[
  _StarterInventoryStock(
    materialId: 'SKU-1001',
    barcode: '8901001000011',
    name: 'Royal Stag Whisky',
    category: 'Whisky',
    qtyOnHand: 24,
    reorderLevel: 8,
  ),
  _StarterInventoryStock(
    materialId: 'SKU-1002',
    barcode: '8901001000028',
    name: 'Blenders Pride Whisky',
    category: 'Whisky',
    qtyOnHand: 18,
    reorderLevel: 6,
  ),
  _StarterInventoryStock(
    materialId: 'SKU-1003',
    barcode: '8901001000035',
    name: 'Kingfisher Premium',
    category: 'Beer',
    qtyOnHand: 48,
    reorderLevel: 20,
  ),
  _StarterInventoryStock(
    materialId: 'SKU-1004',
    barcode: '8901001000042',
    name: 'Bira White',
    category: 'Beer',
    qtyOnHand: 36,
    reorderLevel: 12,
  ),
  _StarterInventoryStock(
    materialId: 'SKU-1005',
    barcode: '8901001000059',
    name: 'Sula Red Wine',
    category: 'Wine',
    qtyOnHand: 12,
    reorderLevel: 4,
  ),
  _StarterInventoryStock(
    materialId: 'SKU-1006',
    barcode: '8901001000066',
    name: 'Bacardi White Rum',
    category: 'Rum',
    qtyOnHand: 16,
    reorderLevel: 6,
  ),
  _StarterInventoryStock(
    materialId: 'SKU-1007',
    barcode: '8901001000073',
    name: 'Magic Moments Vodka',
    category: 'Vodka',
    qtyOnHand: 14,
    reorderLevel: 5,
  ),
  _StarterInventoryStock(
    materialId: 'SKU-1008',
    barcode: '8901001000080',
    name: 'Coca-Cola Can',
    category: 'Soft Drink',
    qtyOnHand: 60,
    reorderLevel: 24,
  ),
];
