import 'dart:io';

import '../../../shared/export/table_excel_exporter.dart';
import 'models/purchase_return_models.dart';

/// Purchase bills (as listed, after filters) → one Excel row per bill.
class PurchaseBillsExport {
  static const headers = [
    'Bill No', 'Date', 'Distributor', 'TP No', 'Challan No', 'Pay Mode', 'Items', 'Bottles',
    'Discount', 'VAT', 'Other / Breakage', 'TCS', 'Loading / Freight', 'Net Amount', 'Status',
  ];

  static List<List<Object?>> rows(List<PurchaseBillDetailDto> bills) => [
        for (final b in bills)
          [
            b.billNo ?? '',
            DateTime.tryParse(b.billDate)?.toLocal() ?? b.billDate,
            b.supplierName,
            b.tpNo ?? '',
            b.challanNo ?? '',
            b.payMode,
            b.lineItems.length,
            b.lineItems.fold<int>(0, (s, l) => s + l.qty),
            b.discount,
            b.vat,
            b.stamp,
            b.tcs,
            b.loadingFreight,
            b.netAmount,
            b.status,
          ],
      ];

  static Future<File> save(List<PurchaseBillDetailDto> bills) => const TableExcelExporter().save(
        fileBaseName: 'purchase_bills',
        sheetName: 'Purchase Bills',
        headers: headers,
        rows: rows(bills),
      );
}
