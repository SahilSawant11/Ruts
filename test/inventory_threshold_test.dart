import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/inventory/data/models/inventory_overview_item.dart';

void main() {
  group('InventoryOverviewItem threshold evaluation', () {
    const itemWithStock8 = InventoryOverviewItem(
      materialId: 'SCM-101',
      barcode: '8901001',
      name: 'Sample Item 1',
      manufacturer: 'Brand A',
      category: 'Spirits',
      packing: '750 ml',
      qtyOnHand: 8,
      reorderLevel: 10,
      saleRate: 500,
    );

    const itemOutOfStock = InventoryOverviewItem(
      materialId: 'SCM-102',
      barcode: '8901002',
      name: 'Sample Item 2',
      manufacturer: 'Brand B',
      category: 'Beer',
      packing: '650 ml Can',
      qtyOnHand: 0,
      reorderLevel: 10,
      saleRate: 200,
    );

    test('evaluates low stock according to configurable threshold', () {
      // With threshold = 10, stock 8 is low stock
      expect(itemWithStock8.isAtRiskFor(10), isTrue);
      expect(itemWithStock8.isLowStockFor(10), isTrue);
      expect(itemWithStock8.isInStockFor(10), isFalse);

      // With threshold = 5, stock 8 is now IN stock
      expect(itemWithStock8.isAtRiskFor(5), isFalse);
      expect(itemWithStock8.isLowStockFor(5), isFalse);
      expect(itemWithStock8.isInStockFor(5), isTrue);
    });

    test('out of stock items are always flagged as out of stock and at risk', () {
      expect(itemOutOfStock.isOutOfStock, isTrue);
      expect(itemOutOfStock.isAtRiskFor(10), isTrue);
      expect(itemOutOfStock.isAtRiskFor(0), isTrue);
      expect(itemOutOfStock.isInStockFor(10), isFalse);
    });
  });
}
