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
      'SELECT m.id, m.barcode, m.name, '
      'COALESCE(m.manufacturer, \'\') AS manufacturer, '
      'COALESCE(m.category, \'\') AS category, '
      'COALESCE(m.packing, \'\') AS packing, '
      'COALESCE(m.sale_rate, 0.0) AS sale_rate, '
      'COALESCE(m.tax_percent, 0.0) AS tax_percent, '
      'COALESCE(s.qty_on_hand, 0) AS stock_qty, '
      'COALESCE(m.is_active, 1) AS is_active, '
      'COALESCE(m.sync_status, \'synced\') AS sync_status '
      'FROM cached_materials m '
      'LEFT JOIN cached_inventory_stocks s ON (s.material_id = m.id OR (s.barcode = m.barcode AND m.barcode != \'\'))',
    ).get();

    final byBarcode = <String, MaterialDto>{};
    final byId = <String, MaterialDto>{};

    for (final row in rows) {
      final id = row.readNullable<String>('id') ?? '';
      final barcode = row.readNullable<String>('barcode') ?? '';
      if (id.isEmpty || barcode.isEmpty) continue;

      final rawStock = row.readNullable<int>('stock_qty') ?? 0;
      final dto = MaterialDto(
        id: id,
        barcode: barcode,
        name: row.readNullable<String>('name') ?? '',
        manufacturer: row.readNullable<String>('manufacturer') ?? '',
        category: row.readNullable<String>('category') ?? '',
        packing: row.readNullable<String>('packing') ?? '',
        saleRate: row.readNullable<double>('sale_rate') ?? 0.0,
        taxPercent: row.readNullable<double>('tax_percent') ?? 0.0,
        stockQty: rawStock < 0 ? 0 : rawStock,
        isActive: (row.readNullable<bool>('is_active') ?? (row.readNullable<int>('is_active') == 1)),
        isPendingSync: (row.readNullable<String>('sync_status') ?? 'synced') != 'synced',
      );
      byBarcode[barcode] = dto;
      byId[id] = dto;
    }
    return MaterialLookupCache._(byBarcode, byId);
  }
}
