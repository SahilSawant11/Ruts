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
    final rows = await db.select(db.cachedMaterials).get();
    final byBarcode = <String, MaterialDto>{};
    final byId = <String, MaterialDto>{};
    for (final row in rows) {
      final dto = MaterialDto(
        id: row.id,
        barcode: row.barcode,
        name: row.name,
        manufacturer: row.manufacturer,
        category: row.category,
        packing: row.packing,
        saleRate: row.saleRate,
        taxPercent: row.taxPercent,
        stockQty: row.stockQty,
        isPendingSync: row.syncStatus != 'synced',
      );
      byBarcode[row.barcode] = dto;
      byId[row.id] = dto;
    }
    return MaterialLookupCache._(byBarcode, byId);
  }
}
