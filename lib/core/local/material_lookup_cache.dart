import '../../features/sales/data/models/material_dto.dart';
import 'app_database.dart';

/// In-memory lookup cache for materials, keyed by barcode and by item-code (id).
/// Provides O(1) scan lookup — no DB query, no network call.
///
/// Loaded once at bootstrap from SQLite; refreshed automatically after
/// material create/update via the [LocalMastersRepository] callback.
/// 49 SKUs now; designed to scale to 20 000+ (≈ 5 MB RAM at that size).
class MaterialLookupCache {
  MaterialLookupCache._(this._byBarcode, this._byId);

  final Map<String, MaterialDto> _byBarcode;
  final Map<String, MaterialDto> _byId;

  /// O(1) lookup — checks barcode first, then item code.
  MaterialDto? findByBarcodeOrId(String code) =>
      _byBarcode[code] ?? _byId[code];

  /// Number of materials in the cache.
  int get length => _byId.length;

  /// Build the cache from the local SQLite table.
  static Future<MaterialLookupCache> load(AppDatabase db) async {
    final rows = await db.customSelect(
      'SELECT id, barcode, name, '
      'COALESCE(manufacturer, \'\') AS manufacturer, '
      'COALESCE(category, \'\') AS category, '
      'COALESCE(packing, \'\') AS packing, '
      'COALESCE(sale_rate, 0.0) AS sale_rate, '
      'COALESCE(tax_percent, 0.0) AS tax_percent, '
      'COALESCE(stock_qty, 0) AS stock_qty, '
      'COALESCE(is_active, 1) AS is_active, '
      'COALESCE(sync_status, \'synced\') AS sync_status '
      'FROM cached_materials',
    ).get();

    final byBarcode = <String, MaterialDto>{};
    final byId = <String, MaterialDto>{};

    for (final row in rows) {
      final id = row.readNullable<String>('id') ?? '';
      final barcode = row.readNullable<String>('barcode') ?? '';
      if (id.isEmpty || barcode.isEmpty) continue;

      final dto = MaterialDto(
        id: id,
        barcode: barcode,
        name: row.readNullable<String>('name') ?? '',
        manufacturer: row.readNullable<String>('manufacturer') ?? '',
        category: row.readNullable<String>('category') ?? '',
        packing: row.readNullable<String>('packing') ?? '',
        saleRate: row.readNullable<double>('sale_rate') ?? 0.0,
        taxPercent: row.readNullable<double>('tax_percent') ?? 0.0,
        stockQty: row.readNullable<int>('stock_qty') ?? 0,
        isActive: (row.readNullable<bool>('is_active') ?? (row.readNullable<int>('is_active') == 1)),
        isPendingSync: (row.readNullable<String>('sync_status') ?? 'synced') != 'synced',
      );
      byBarcode[barcode] = dto;
      byId[id] = dto;
    }
    return MaterialLookupCache._(byBarcode, byId);
  }
}
