import '../../features/sales/data/models/material_dto.dart';
import 'app_database.dart';

/// Picks the material a scanned/typed [code] means. One barcode (or SCM
/// code) can belong to several materials of the same counter brand, so:
/// exact id first, then barcode, then SCM code — preferring active rows
/// with the most stock.
MaterialDto? pickMaterialForCode(Iterable<MaterialDto> materials, String code) {
  final c = code.trim();
  if (c.isEmpty) return null;
  MaterialDto? best(Iterable<MaterialDto> xs) {
    MaterialDto? pick;
    for (final m in xs) {
      if (pick == null) {
        pick = m;
        continue;
      }
      if (m.isActive != pick.isActive) {
        if (m.isActive) pick = m;
        continue;
      }
      if (m.stockQty > pick.stockQty) pick = m;
    }
    return pick;
  }

  for (final m in materials) {
    if (m.id == c) return m;
  }
  return best(materials.where((m) => m.barcode == c)) ?? best(materials.where((m) => m.scmCode == c));
}

/// In-memory lookup cache for materials, keyed by barcode, SCM code and id.
/// Provides O(1)-ish scan lookup — no DB query, no network call.
///
/// Loaded once at bootstrap from SQLite; refreshed automatically after
/// material create/update via the [LocalMastersRepository] callback.
class MaterialLookupCache {
  MaterialLookupCache._(this._byCode, this._byId);

  /// Barcode / SCM code → every material carrying it.
  final Map<String, List<MaterialDto>> _byCode;
  final Map<String, MaterialDto> _byId;

  /// Checks item id, then barcode, then SCM code. Shared codes resolve to
  /// the active material with the most stock.
  MaterialDto? findByBarcodeOrId(String code) {
    final c = code.trim();
    return _byId[c] ?? pickMaterialForCode(_byCode[c] ?? const [], c);
  }

  /// Every material a barcode / SCM code / id stands for.
  List<MaterialDto> allForCode(String code) {
    final c = code.trim();
    final byId = _byId[c];
    if (byId != null) return [byId];
    return _byCode[c] ?? const [];
  }

  /// Number of materials in the cache.
  int get length => _byId.length;

  static MaterialLookupCache fromMaterials(Iterable<MaterialDto> materials) {
    final byCode = <String, List<MaterialDto>>{};
    final byId = <String, MaterialDto>{};
    for (final m in materials) {
      if (m.id.isEmpty) continue;
      byId[m.id] = m;
      for (final k in {m.barcode, m.scmCode}) {
        if (k.isNotEmpty) byCode.putIfAbsent(k, () => []).add(m);
      }
    }
    return MaterialLookupCache._(byCode, byId);
  }

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
      'COALESCE(m.sync_status, \'synced\') AS sync_status, '
      'm.scm_code, m.liquor_type, m.counter_brand_name, m.counter_brand_id, '
      'm.wholesale_rate, m.discount_percent '
      'FROM cached_materials m '
      'LEFT JOIN cached_inventory_stocks s ON s.material_id = m.id',
    ).get();

    final materials = <MaterialDto>[];
    for (final row in rows) {
      final id = row.readNullable<String>('id') ?? '';
      final barcode = row.readNullable<String>('barcode') ?? '';
      if (id.isEmpty || barcode.isEmpty) continue;
      final rawStock = row.readNullable<int>('stock_qty') ?? 0;
      final scm = row.readNullable<String>('scm_code') ?? '';
      materials.add(MaterialDto(
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
        scmCode: scm.isEmpty ? id : scm,
        liquorType: row.readNullable<String>('liquor_type') ?? '',
        counterBrandName: row.readNullable<String>('counter_brand_name') ?? '',
        counterBrandId: row.readNullable<String>('counter_brand_id') ?? '',
        wholesaleRate: row.readNullable<double>('wholesale_rate') ?? 0,
        discountPercent: row.readNullable<double>('discount_percent') ?? 0,
      ));
    }
    return fromMaterials(materials);
  }
}
