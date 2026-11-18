import 'dart:io';

import '../../../shared/export/table_excel_exporter.dart';
import 'models/sales_return_models.dart';

/// Sales bills (as listed, after filters) → one Excel row per bill.
class SalesBillsExport {
  static const headers = [
    'Bill No', 'Date', 'Permit No', 'Permit Holder', 'Pay Mode', 'Items', 'Bottles',
    'Taxable', 'Tax', 'Total', 'Status',
  ];

  static List<List<Object?>> rows(List<SalesBillDetailDto> bills) => [
        for (final b in bills)
          [
            b.billNo,
            DateTime.tryParse(b.billDate)?.toLocal() ?? b.billDate,
            b.permitNo ?? '',
            b.permitHolderName ?? b.customerName ?? '',
            b.payMode,
            b.lineItems.length,
            b.lineItems.fold<int>(0, (s, l) => s + l.quantity),
            b.taxableValue,
            b.totalTax,
            b.totalAmount,
            b.status,
          ],
      ];

  static Future<File> save(List<SalesBillDetailDto> bills) => const TableExcelExporter().save(
        fileBaseName: 'sales_bills',
        sheetName: 'Sales Bills',
        headers: headers,
        rows: rows(bills),
      );
}
