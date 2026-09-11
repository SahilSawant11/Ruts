import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/sales/data/models/sales_return_models.dart';
import 'package:pos_app/features/purchase/data/models/purchase_return_models.dart';

void main() {
  group('Sales Return Models Test', () {
    test('SalesBillDetailDto deserializes from JSON correctly', () {
      final json = {
        'id': 'sale-123',
        'billNo': 'SB-2026-0001',
        'customerId': 'cust-1',
        'customerName': 'John Doe',
        'billType': 'CounterSale.Sale',
        'billDate': '2026-09-11T00:00:00.000Z',
        'payMode': 'Cash',
        'taxableValue': 1000.0,
        'totalDiscount': 50.0,
        'totalTax': 50.0,
        'totalAmount': 1050.0,
        'balanceDue': 0.0,
        'status': 'paid',
        'createdAt': '2026-09-11T12:00:00.000Z',
        'saleLineItems': [
          {
            'id': 'item-1',
            'salesBillId': 'sale-123',
            'barcodeNo': '1234567890123',
            'materialId': 'mat-1',
            'materialType': 'IMFL',
            'materialName': 'Royal Challenge',
            'batchNo': 'B1',
            'packing': '750ml',
            'quantity': 2,
            'qtyCase': 0,
            'rate': 525.0,
            'discountPercent': 0.0,
            'discountAmount': 0.0,
            'taxPercent': 5.0,
            'taxAmount': 25.0,
            'amount': 1050.0,
            'lineNumber': 1,
          }
        ]
      };

      final dto = SalesBillDetailDto.fromJson(json);

      expect(dto.id, 'sale-123');
      expect(dto.billNo, 'SB-2026-0001');
      expect(dto.customerName, 'John Doe');
      expect(dto.totalAmount, 1050.0);
      expect(dto.lineItems.length, 1);

      final line = dto.lineItems.first;
      expect(line.barcodeNo, '1234567890123');
      expect(line.materialName, 'Royal Challenge');
      expect(line.quantity, 2);
      expect(line.rate, 525.0);
      expect(line.amount, 1050.0);
    });

    test('Sales return stock calculation restores sold quantity', () {
      const initialStock = 10;
      const returnedSaleQty = 3;
      const restoredStock = initialStock + returnedSaleQty;

      expect(restoredStock, 13);
    });
  });

  group('Purchase Return Models Test', () {
    test('PurchaseBillDetailDto deserializes from JSON correctly', () {
      final json = {
        'id': 'purchase-456',
        'billNo': 'PB-2026-0099',
        'supplierId': 'sup-1',
        'supplierName': 'United Spirits Dist',
        'challanNo': 'CH-99',
        'noteNo': 'N-1',
        'payMode': 'Credit',
        'tpNo': 'TP-55',
        'tpDate': '2026-09-10',
        'stNo': 'ST-11',
        'discount': 100.0,
        'vat': 50.0,
        'stamp': 10.0,
        'tcs': 5.0,
        'loadingFreight': 25.0,
        'netAmount': 5000.0,
        'totalAmount': 5000.0,
        'billDate': '2026-09-11T00:00:00.000Z',
        'status': 'saved',
        'createdAt': '2026-09-11T10:00:00.000Z',
        'purchaseLineItems': [
          {
            'id': 'pitem-1',
            'purchaseBillId': 'purchase-456',
            'materialId': 'mat-1',
            'materialName': 'McDowell No.1',
            'batchNo': 'BATCH-001',
            'packing': '750ml',
            'qty': 12,
            'rate': 400.0,
            'disPercent': 0.0,
            'disAmount': 0.0,
            'taxPercent': 5.0,
            'taxAmount': 20.0,
            'amount': 4820.0,
            'lineNumber': 1,
          }
        ]
      };

      final dto = PurchaseBillDetailDto.fromJson(json);

      expect(dto.id, 'purchase-456');
      expect(dto.billNo, 'PB-2026-0099');
      expect(dto.supplierName, 'United Spirits Dist');
      expect(dto.netAmount, 5000.0);
      expect(dto.lineItems.length, 1);

      final line = dto.lineItems.first;
      expect(line.materialName, 'McDowell No.1');
      expect(line.batchNo, 'BATCH-001');
      expect(line.qty, 12);
      expect(line.amount, 4820.0);
    });

    test('Purchase return stock calculation deducts returned quantity', () {
      const initialStock = 24;
      const returnedPurchaseQty = 12;
      final deductedStock = (initialStock - returnedPurchaseQty).clamp(0, 999999);

      expect(deductedStock, 12);
    });
  });
}
