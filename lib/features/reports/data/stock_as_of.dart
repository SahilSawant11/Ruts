import '../../../core/local/app_database.dart';
import 'stock_movements.dart';

/// Stock on hand per product at [endExclusive] (the start of the day
/// after the report date), worked back from today's stock:
///
///   closing(day) = stock now + (sold − returned by customers) after the day
///                            − (received − sent back) after the day
///
/// Every movement counts on the day it happened (returns on the return
/// day), the same rule the reports use, so a past day's closing never
/// changes later. For today this is just stock now.
Future<Map<String, int>> closingStockAsOf(AppDatabase db, DateTime endExclusive) async {
  final stock = {
    for (final s in await db.select(db.cachedInventoryStocks).get()) s.materialId: s.qtyOnHand,
  };
  final after = await stockMovements(db, endExclusive, DateTime(9999));
  for (final id in after.materialIds) {
    stock[id] = (stock[id] ?? 0) + after.netSale(id) - after.netPurchase(id);
  }
  return stock;
}
