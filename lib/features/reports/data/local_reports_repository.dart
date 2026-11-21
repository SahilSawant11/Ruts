import 'package:drift/drift.dart' hide Column;

import '../../../core/config/app_config.dart';
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
    if (!AppConfig.offlineOnly) {
      try {
        await _sales.syncPendingSales();
      } on ApiException {
        // Fall through to local data below.
      }
    }

    final local = await _buildLocalSalesReport(
      from: from,
      to: to,
      category: category,
      manufacturer: manufacturer,
    );
    if (AppConfig.offlineOnly || local.totalBills > 0) return local;
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
    final start = DateTime(from.year, from.month, from.day, from.hour, from.minute, from.second);
    final hasToTime = to.hour != 0 || to.minute != 0 || to.second != 0;
    final end = hasToTime
        ? DateTime(to.year, to.month, to.day, to.hour, to.minute, to.second, 999)
        : DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    final normalizedCategory = category?.trim();
    final normalizedManufacturer = manufacturer?.trim();

    // Every bill of the period counts, as sold; bottles brought back count
    // (as minus) on the day of the return, so a past period never changes.
    final bills = await (_db.select(_db.cachedSalesBills)
          ..where((tbl) =>
              tbl.billDate.isBiggerOrEqualValue(start) &
              tbl.billDate.isSmallerOrEqualValue(end)))
        .get();

    final lines = await (_db.select(_db.cachedSaleLineItems)
          ..where((tbl) => _db.lineOfActiveBillBetween(tbl, start, end, endInclusive: true, includeReturned: true)))
        .get();
    final materials = await _db.select(_db.cachedMaterials).get();
    final materialById = {for (final m in materials) m.id: m};
    final billIds = {for (final b in bills) b.id};
    // What partial returns took off this period's bills (added back: as sold)…
    final takenOff = (await (_db.select(_db.salesReturnEntries)
              ..where((e) => e.isFullBillReturn.equals(false)))
            .get())
        .where((e) => billIds.contains(e.salesBillId));
    // …and every bottle brought back during the period (taken off).
    final broughtBack = await (_db.select(_db.salesReturnEntries)
          ..where((e) => e.returnedAt.isBiggerOrEqualValue(start) & e.returnedAt.isSmallerOrEqualValue(end)))
        .get();
    final entryLines = [
      for (final e in takenOff) (e, 1),
      for (final e in broughtBack) (e, -1),
    ];
    final manufacturerByMaterialId = {
      for (final material in materials) material.id: material.manufacturer,
    };
    final manufacturerByBarcode = {
      for (final material in materials) material.barcode: material.manufacturer,
    };

    final grouped = <String, _Agg>{};
    for (final line in lines) {
      final matId = line.materialId ?? '';
      final barcode = line.barcodeNo;
      // Sold is sold: a material made inactive later still counts here.
      if (normalizedCategory != null && normalizedCategory.isNotEmpty && line.materialType != normalizedCategory) {
        continue;
      }
      final manufacturerName = manufacturerByMaterialId[matId] ??
          manufacturerByBarcode[barcode] ??
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

    for (final (e, sign) in entryLines) {
      final mat = materialById[e.materialId ?? ''];
      final type = mat?.category ?? '';
      if (normalizedCategory != null && normalizedCategory.isNotEmpty && type != normalizedCategory) continue;
      final manufacturerName = mat?.manufacturer ?? manufacturerByBarcode[e.barcodeNo] ?? '';
      if (normalizedManufacturer != null &&
          normalizedManufacturer.isNotEmpty &&
          manufacturerName != normalizedManufacturer) {
        continue;
      }
      final packing = mat?.packing;
      final key = '${e.barcodeNo}|${e.materialName}|$manufacturerName|${packing ?? ''}';
      final agg = grouped.putIfAbsent(
        key,
        () => _Agg(materialId: e.barcodeNo, materialName: e.materialName, manufacturer: manufacturerName, packing: packing),
      );
      agg.qtyLoose += sign * e.quantity;
      agg.amount += sign * e.amount;
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
      totalAmount: items.fold(0.0, (sum, item) => sum + item.amount),
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
