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
  /// from the sale bills that carry that permit. A bill counts on its own
  /// day as it was sold; bottles the customer brings back come off on the
  /// day of the return (so a past period's figures never change). Sorted
  /// by quantity, highest first.
  static Future<LicenseHolderReport> build(AppDatabase db, DateTime from, DateTime to) async {
    final range = [Variable.withDateTime(from), Variable.withDateTime(to)];
    final holders = {
      for (final h in await db.select(db.cachedLicenseHolders).get())
        if (h.permitNo.trim().isNotEmpty) h.permitNo.trim(): h,
    };
    final agg = <String, _Agg>{};
    _Agg of(String? permit, String? name) =>
        agg.putIfAbsent(permit!.trim(), () => _Agg(name?.trim() ?? ''));

    // Bills of the period, as sold (current lines + what partial returns took off).
    for (final r in await db.customSelect('''
      SELECT b.permit_no AS permit, b.permit_holder_name AS name, COUNT(*) AS bills,
        COALESCE(SUM((SELECT SUM(l.qty_case) FROM cached_sale_line_items l WHERE l.sales_bill_id = b.id)), 0) AS cases,
        COALESCE(SUM((SELECT SUM(l.quantity) FROM cached_sale_line_items l WHERE l.sales_bill_id = b.id)), 0)
          + COALESCE(SUM((SELECT SUM(e.quantity) FROM sales_return_entries e
              WHERE e.sales_bill_id = b.id AND e.is_full_bill_return = 0)), 0) AS bottles,
        COALESCE(SUM((SELECT SUM(l.amount) FROM cached_sale_line_items l WHERE l.sales_bill_id = b.id)), 0)
          + COALESCE(SUM((SELECT SUM(e.amount) FROM sales_return_entries e
              WHERE e.sales_bill_id = b.id AND e.is_full_bill_return = 0)), 0) AS amount
      FROM cached_sales_bills b
      WHERE TRIM(COALESCE(b.permit_no, '')) <> '' AND b.bill_date >= ? AND b.bill_date <= ?
      GROUP BY TRIM(b.permit_no)''', variables: range).get()) {
      final a = of(r.read<String>('permit'), r.readNullable<String>('name'));
      a.bills += r.read<int>('bills');
      a.qtyCase += r.read<int>('cases');
      a.qtyBottles += r.read<int>('bottles');
      a.amount += r.read<double>('amount');
    }

    // Bottles brought back during the period, whatever day the bill was.
    for (final r in await db.customSelect('''
      SELECT b.permit_no AS permit, b.permit_holder_name AS name,
        SUM(e.quantity) AS bottles, SUM(e.amount) AS amount
      FROM sales_return_entries e JOIN cached_sales_bills b ON b.id = e.sales_bill_id
      WHERE TRIM(COALESCE(b.permit_no, '')) <> '' AND e.returned_at >= ? AND e.returned_at <= ?
      GROUP BY TRIM(b.permit_no)''', variables: range).get()) {
      final a = of(r.read<String>('permit'), r.readNullable<String>('name'));
      a.qtyBottles -= r.read<int>('bottles');
      a.amount -= r.read<double>('amount');
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
