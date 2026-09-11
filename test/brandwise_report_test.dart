import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/reports/data/models/brandwise_report_dto.dart';

void main() {
  group('BrandwiseSizeQty', () {
    test('addition and byIndex works correctly', () {
      const a = BrandwiseSizeQty(
        wine750: 10,
        wine375: 5,
        wine180: 2,
        beer650: 12,
        beer500Can: 24,
        beer330Can: 6,
        beer330Bottle: 1,
      );

      const b = BrandwiseSizeQty(
        wine750: 5,
        wine375: 5,
        wine180: 3,
        beer650: 8,
        beer500Can: 0,
        beer330Can: 4,
        beer330Bottle: 2,
      );

      final sum = a + b;
      expect(sum.wine750, 15);
      expect(sum.wine375, 10);
      expect(sum.wine180, 5);
      expect(sum.beer650, 20);
      expect(sum.beer500Can, 24);
      expect(sum.beer330Can, 10);
      expect(sum.beer330Bottle, 3);
      expect(sum.total, 87);

      expect(sum.byIndex(0), 15);
      expect(sum.byIndex(3), 20);
      expect(sum.byIndex(6), 3);
      expect(sum.byIndex(99), 0);
    });

    test('Category subtotal computation', () {
      final items = [
        const BrandwiseReportItemDto(
          brandName: 'Budweiser Magnum',
          openingBalance: BrandwiseSizeQty(beer650: 10, beer500Can: 5),
          purchase: BrandwiseSizeQty(beer650: 20),
          sale: BrandwiseSizeQty(beer650: 5, beer500Can: 2),
          closingBalance: BrandwiseSizeQty(beer650: 25, beer500Can: 3),
        ),
        const BrandwiseReportItemDto(
          brandName: 'Kingfisher Ultra',
          openingBalance: BrandwiseSizeQty(beer650: 15, beer330Can: 12),
          purchase: BrandwiseSizeQty(beer330Can: 24),
          sale: BrandwiseSizeQty(beer650: 10, beer330Can: 6),
          closingBalance: BrandwiseSizeQty(beer650: 5, beer330Can: 30),
        ),
      ];

      final subtotal = BrandwiseCategorySubtotal.compute(items);
      expect(subtotal.openingBalance.beer650, 25);
      expect(subtotal.openingBalance.beer500Can, 5);
      expect(subtotal.openingBalance.beer330Can, 12);
      expect(subtotal.purchase.beer650, 20);
      expect(subtotal.purchase.beer330Can, 24);
      expect(subtotal.sale.beer650, 15);
      expect(subtotal.sale.beer500Can, 2);
      expect(subtotal.sale.beer330Can, 6);
      expect(subtotal.closingBalance.beer650, 30);
      expect(subtotal.closingBalance.beer500Can, 3);
      expect(subtotal.closingBalance.beer330Can, 30);
    });
  });
}
