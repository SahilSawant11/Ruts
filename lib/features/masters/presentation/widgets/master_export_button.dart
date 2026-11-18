import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/export/export_excel_button.dart';
import '../../../../shared/export/table_excel_exporter.dart';
import '../../data/master_import_service.dart';
import '../../data/master_template_service.dart';
import '../../data/masters_providers.dart';

enum MasterExportKind { materials, suppliers, licenseHolders, categories, manufacturers, packings }

/// Exports every record of a master to Excel. Materials, distributors and
/// permit holders use the import template's columns, so an export can be
/// edited and imported straight back.
class MasterExportButton extends ConsumerWidget {
  const MasterExportButton({super.key, required this.kind});

  final MasterExportKind kind;

  static Future<File> export(WidgetRef ref, MasterExportKind kind) async {
    const x = TableExcelExporter();
    const t = MasterTemplateService.headers;
    switch (kind) {
      case MasterExportKind.materials:
        final list = await ref.read(materialsListProvider.future);
        final supplierNames = {for (final s in await ref.read(suppliersListProvider.future)) s.id: s.name};
        return x.save(
          fileBaseName: 'materials',
          sheetName: 'Materials',
          headers: [...t[MasterImportTarget.materials]!, 'Counter Brand ID', 'Stock Qty', 'Active'],
          rows: [
            for (final m in list)
              [m.scmCode, m.barcode, m.name, m.category, m.liquorType, m.packing, m.manufacturer,
                m.counterBrandName, m.saleRate, m.wholesaleRate, m.taxPercent, m.discountPercent,
                supplierNames[m.defaultSupplierId] ?? '', m.counterBrandId, m.stockQty, m.isActive ? 'Yes' : 'No'],
          ],
        );
      case MasterExportKind.suppliers:
        final list = await ref.read(suppliersListProvider.future);
        return x.save(
          fileBaseName: 'distributors',
          sheetName: 'Distributors',
          headers: t[MasterImportTarget.suppliers]!,
          rows: [
            for (final s in list)
              [s.name, s.address, s.contactNo, s.email, s.vatNo, s.bankDetails, s.disPercent,
                s.openingBalance, s.balanceType],
          ],
        );
      case MasterExportKind.licenseHolders:
        final list = await ref.read(licenseHoldersListProvider.future);
        return x.save(
          fileBaseName: 'permit_holders',
          sheetName: 'Permit Holders',
          headers: t[MasterImportTarget.licenseHolders]!,
          rows: [
            for (final h in list)
              [h.permitNo, h.name, h.issuedDate, h.city, h.validity, h.address, h.contactNo, h.remark, h.category],
          ],
        );
      case MasterExportKind.categories:
        final list = await ref.read(categoriesListProvider.future);
        return x.save(
          fileBaseName: 'categories',
          sheetName: 'Categories',
          headers: const ['Name', 'Description'],
          rows: [for (final c in list) [c.name, c.description]],
        );
      case MasterExportKind.manufacturers:
        final list = await ref.read(manufacturersListProvider.future);
        return x.save(
          fileBaseName: 'manufacturers',
          sheetName: 'Manufacturers',
          headers: const ['Name', 'Description'],
          rows: [for (final m in list) [m.name, m.description]],
        );
      case MasterExportKind.packings:
        final list = await ref.read(packingsListProvider.future);
        return x.save(
          fileBaseName: 'packings',
          sheetName: 'Packings',
          headers: const ['Name', 'Description'],
          rows: [for (final p in list) [p.name, p.description]],
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExportExcelButton(onExport: () => export(ref, kind));
  }
}
