import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/sales/data/local_sales_repository.dart';
import 'package:pos_app/features/sales/data/models/create_sale_request.dart';
import 'package:pos_app/features/sales/data/models/material_dto.dart';
import 'package:pos_app/features/sales/presentation/cart_controller.dart';

class _FakeSalesRepository implements LocalSalesRepository {
  final Map<String, MaterialDto> materials = {
    '890123456789': const MaterialDto(
      id: 'm1',
      barcode: '890123456789',
      name: 'ROYAL CHALLENGE 750ML',
      manufacturer: 'USL',
      category: 'WHISKY',
      packing: '750ml',
      saleRate: 850.0,
      taxPercent: 18.0,
      stockQty: 50,
    ),
    '890987654321': const MaterialDto(
      id: 'm2',
      barcode: '890987654321',
      name: 'KINGFISHER PREMIUM 650ML',
      manufacturer: 'UBL',
      category: 'BEER',
      packing: '650ml',
      saleRate: 180.0,
      taxPercent: 18.0,
      stockQty: 100,
    ),
  };

  @override
  Future<MaterialDto?> getMaterialByBarcode(String barcode) async {
    return materials[barcode];
  }

  @override
  Future<CreateSaleResult> createSale(CreateSaleRequest request) async {
    return CreateSaleResult(id: 'sale-1', billNo: request.billNo, lineItemCount: request.lineItems.length);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CartController Redesign Tests', () {
    late CartController controller;
    late _FakeSalesRepository repo;

    setUp(() {
      repo = _FakeSalesRepository();
      controller = CartController(repo);
    });

    test('addByBarcode with custom qty adds correct item and computes totals', () async {
      await controller.addByBarcode('890123456789', qty: 2);

      expect(controller.state.items.length, 1);
      final item = controller.state.items.first;
      expect(item.material, 'ROYAL CHALLENGE 750ML');
      expect(item.qty, 2);
      expect(item.rate, 850.0);
      expect(item.taxPercent, 18.0);
      // gross = 1700, tax = 1700 * 0.18 = 306, total = 2006
      expect(item.taxAmount, 306.0);
      expect(item.amount, 2006.0);

      expect(controller.state.totalQty, 2);
      expect(controller.state.taxableValue, 1700.0);
      expect(controller.state.totalTax, 306.0);
      expect(controller.state.totalAmount, 2006.0);
    });

    test('updateQty updates line item quantity and recalculates totals', () async {
      await controller.addByBarcode('890123456789', qty: 2);
      expect(controller.state.totalQty, 2);

      controller.updateQty(0, 5);
      expect(controller.state.items[0].qty, 5);
      expect(controller.state.totalQty, 5);
      // gross = 5 * 850 = 4250, tax = 4250 * 0.18 = 765, total = 5015
      expect(controller.state.totalAmount, 5015.0);
    });

    test('updating qty to 0 removes line item and re-indexes', () async {
      await controller.addByBarcode('890123456789', qty: 1);
      await controller.addByBarcode('890987654321', qty: 3);
      expect(controller.state.items.length, 2);

      controller.updateQty(0, 0); // Should remove item at index 0
      expect(controller.state.items.length, 1);
      expect(controller.state.items[0].material, 'KINGFISHER PREMIUM 650ML');
      expect(controller.state.items[0].index, 1); // Reindexed to 1
    });
  });
}
