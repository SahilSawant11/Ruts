import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:excel_community/excel_community.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/local/app_database.dart';

/// One license (permit) and what was sold against it in the range.
class LicenseHolderReportRow {
  const LicenseHolderReportRow({
    required this.permitNo,
    required this.name,
    required this.validity,
    required this.bills,
    required this.qtyCase,
    required this.qtyBottles,
    required this.amount,
  });

  final String permitNo;
  final String name;
  final String validity;
  final int bills;
  final int qtyCase;
  final int qtyBottles;
  final double amount;
}

class LicenseHolderReport {
  const LicenseHolderReport({required this.from, required this.to, required this.rows});

  final DateTime from;
  final DateTime to;
  final List<LicenseHolderReportRow> rows;

  int get totalBills => rows.fold(0, (s, r) => s + r.bills);
  int get totalQtyCase => rows.fold(0, (s, r) => s + r.qtyCase);
  int get totalQtyBottles => rows.fold(0, (s, r) => s + r.qtyBottles);
  double get totalAmount => rows.fold(0.0, (s, r) => s + r.amount);

  /// Quantity sold per license number over [from]..[to] (both inclusive),
  /// from the sale bills that carry that permit. Returned bills don't count.
  /// Sorted by quantity, highest first.
  static Future<LicenseHolderReport> build(AppDatabase db, DateTime from, DateTime to) async {
    final bills = await (db.select(db.cachedSalesBills)
          ..where((t) =>
              db.isActiveSaleBill(t) &
              t.billDate.isBiggerOrEqualValue(from) &
              t.billDate.isSmallerOrEqualValue(to)))
        .get();
    final lines = await (db.select(db.cachedSaleLineItems)
          ..where((t) => db.lineOfActiveBillBetween(t, from, to, endInclusive: true)))
        .get();
    final holders = {
      for (final h in await db.select(db.cachedLicenseHolders).get())
        if (h.permitNo.trim().isNotEmpty) h.permitNo.trim(): h,
    };

    final cases = <String, int>{};
    final bottles = <String, int>{};
    final amounts = <String, double>{};
    for (final l in lines) {
      amounts[l.salesBillId] = (amounts[l.salesBillId] ?? 0) + l.amount;
      cases[l.salesBillId] = (cases[l.salesBillId] ?? 0) + l.qtyCase;
      bottles[l.salesBillId] = (bottles[l.salesBillId] ?? 0) + l.quantity;
    }

    final agg = <String, _Agg>{};
    for (final b in bills) {
      final permit = b.permitNo?.trim() ?? '';
      if (permit.isEmpty) continue;
      final a = agg.putIfAbsent(permit, () => _Agg(b.permitHolderName?.trim() ?? ''));
      a.bills++;
      a.qtyCase += cases[b.id] ?? 0;
      a.qtyBottles += bottles[b.id] ?? 0;
      a.amount += amounts[b.id] ?? 0;
    }

    final rows = [
      for (final e in agg.entries)
        LicenseHolderReportRow(
          permitNo: e.key,
          name: (holders[e.key]?.name.trim().isNotEmpty ?? false) ? holders[e.key]!.name.trim() : e.value.name,
          validity: holders[e.key]?.validity ?? '',
          bills: e.value.bills,
          qtyCase: e.value.qtyCase,
          qtyBottles: e.value.qtyBottles,
          amount: e.value.amount,
        ),
    ]..sort((a, b) {
        final byQty = b.qtyBottles.compareTo(a.qtyBottles);
        return byQty != 0 ? byQty : a.permitNo.compareTo(b.permitNo);
      });
    return LicenseHolderReport(from: from, to: to, rows: rows);
  }
}

class _Agg {
  _Agg(this.name);
  final String name;
  int bills = 0;
  int qtyCase = 0;
  int qtyBottles = 0;
  double amount = 0;
}

/// License holder report as .xlsx: a header row, one row per license,
/// then a Total row.
class LicenseHolderReportExporter {
  static const headers = [
    'Sr', 'License No', 'Name', 'Validity', 'Bills', 'Qty (Case)', 'Qty (Bottles)', 'Amount',
  ];
  static const _widths = [6.0, 16.0, 34.0, 12.0, 8.0, 11.0, 13.0, 13.0];

  static List<int> encode(LicenseHolderReport report) {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet() ?? 'Sheet1'];
    sheet.appendRow([for (final h in headers) TextCellValue(h)]);
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = CellStyle(bold: true);
      sheet.setColumnWidth(i, _widths[i]);
    }
    for (var i = 0; i < report.rows.length; i++) {
      final r = report.rows[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(r.permitNo),
        TextCellValue(r.name),
        TextCellValue(r.validity),
        IntCellValue(r.bills),
        IntCellValue(r.qtyCase),
        IntCellValue(r.qtyBottles),
        DoubleCellValue(double.parse(r.amount.toStringAsFixed(2))),
      ]);
    }
    sheet.appendRow([
      null,
      null,
      TextCellValue('Total'),
      null,
      IntCellValue(report.totalBills),
      IntCellValue(report.totalQtyCase),
      IntCellValue(report.totalQtyBottles),
      DoubleCellValue(double.parse(report.totalAmount.toStringAsFixed(2))),
    ]);
    final last = report.rows.length + 1;
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: last)).cellStyle = CellStyle(bold: true);
    }
    return excel.encode()!;
  }

  Future<File> export(LicenseHolderReport report) async {
    final base = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}Caskly Reports');
    await dir.create(recursive: true);
    final a = _stamp(report.from), b = _stamp(report.to);
    final file = File('${dir.path}${Platform.pathSeparator}license_holders_${a == b ? a : '${a}_to_$b'}.xlsx');
    await file.writeAsBytes(encode(report));
    return file;
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
  static String _stamp(DateTime d) => '${d.year}${_two(d.month)}${_two(d.day)}';
}
