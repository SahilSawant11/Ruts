import 'package:drift/drift.dart' hide Column;

import '../../../core/local/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../sales/data/local_sales_repository.dart';
import 'models/sales_report_dto.dart';
import 'reports_api_repository.dart';

class LocalReportsRepository {
  LocalReportsRepository(this._db, this._remote, this._sales);

  final AppDatabase _db;
  final ReportsApiRepository _remote;
  final LocalSalesRepository _sales;

  Future<SalesReportDto> getSalesReport({
    required DateTime from,
    required DateTime to,
    String? category,
    String? manufacturer,
  }) async {
    try {
      await _sales.syncPendingSales();
    } on ApiException {
      // Fall through to local data below.
    }

    final local = await _buildLocalSalesReport(
      from: from,
      to: to,
      category: category,
      manufacturer: manufacturer,
    );
    if (local.totalBills > 0) return local;
    if ((category?.trim().isNotEmpty ?? false) || (manufacturer?.trim().isNotEmpty ?? false)) {
      return local;
    }

    try {
      return await _remote.getSalesReport(from: from, to: to);
    } on ApiException {
      return local;
    }
  }

  Future<SalesReportDto> _buildLocalSalesReport({
    required DateTime from,
    required DateTime to,
    String? category,
    String? manufacturer,
  }) async {
    final start = DateTime(from.year, from.month, from.day);
    final endExclusive = DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
    final normalizedCategory = category?.trim();
    final normalizedManufacturer = manufacturer?.trim();

    final bills = await (_db.select(_db.cachedSalesBills)
          ..where((tbl) => tbl.billDate.isBiggerOrEqualValue(start) & tbl.billDate.isSmallerThanValue(endExclusive)))
        .get();

    if (bills.isEmpty) {
      return SalesReportDto(
        fromDate: start,
        toDate: DateTime(to.year, to.month, to.day),
        totalBills: 0,
        distinctBrands: 0,
        totalQtyCase: 0,
        totalQtyLoose: 0,
        totalAmount: 0,
        totalTax: 0,
        items: const [],
      );
    }

    final billIds = bills.map((b) => b.id).toList();
    final lines = await (_db.select(_db.cachedSaleLineItems)
          ..where((tbl) => tbl.salesBillId.isIn(billIds)))
        .get();
    final materials = await _db.select(_db.cachedMaterials).get();
    final manufacturerByMaterialId = {
      for (final material in materials) material.id: material.manufacturer,
    };
    final manufacturerByBarcode = {
      for (final material in materials) material.barcode: material.manufacturer,
    };

    final grouped = <String, _Agg>{};
    for (final line in lines) {
      if (normalizedCategory != null && normalizedCategory.isNotEmpty && line.materialType != normalizedCategory) {
        continue;
      }
      final manufacturerName = manufacturerByMaterialId[line.materialId ?? ''] ??
          manufacturerByBarcode[line.barcodeNo] ??
          '';
      if (normalizedManufacturer != null &&
          normalizedManufacturer.isNotEmpty &&
          manufacturerName != normalizedManufacturer) {
        continue;
      }
      final key = '${line.barcodeNo}|${line.materialName}|$manufacturerName|${line.packing ?? ''}';
      final agg = grouped.putIfAbsent(
        key,
        () => _Agg(
          materialId: line.barcodeNo,
          materialName: line.materialName,
          manufacturer: manufacturerName,
          packing: line.packing,
        ),
      );
      agg.qtyCase += line.qtyCase;
      agg.qtyLoose += line.quantity;
      agg.amount += line.amount;
    }

    final items = grouped.values
        .map(
          (agg) => SalesReportItemDto(
            materialId: agg.materialId,
            materialName: agg.materialName,
            manufacturer: agg.manufacturer,
            packing: agg.packing,
            qtyCase: agg.qtyCase,
            qtyLoose: agg.qtyLoose,
            amount: agg.amount,
          ),
        )
        .toList()
      ..sort((a, b) => a.materialName.compareTo(b.materialName));

    return SalesReportDto(
      fromDate: start,
      toDate: DateTime(to.year, to.month, to.day),
      totalBills: grouped.isEmpty ? 0 : bills.length,
      distinctBrands: items.length,
      totalQtyCase: items.fold(0, (sum, item) => sum + item.qtyCase),
      totalQtyLoose: items.fold(0, (sum, item) => sum + item.qtyLoose),
      totalAmount: bills.fold(0.0, (sum, bill) => sum + bill.totalAmount),
      totalTax: bills.fold(0.0, (sum, bill) => sum + bill.totalTax),
      items: items,
    );
  }
}

class _Agg {
  _Agg({
    required this.materialId,
    required this.materialName,
    required this.manufacturer,
    required this.packing,
  });

  final String materialId;
  final String materialName;
  final String manufacturer;
  final String? packing;
  int qtyCase = 0;
  int qtyLoose = 0;
  double amount = 0;
}
