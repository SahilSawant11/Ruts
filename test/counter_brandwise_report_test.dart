import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/reports/data/models/brandwise_report_dto.dart';
import 'package:pos_app/features/reports/data/models/counter_brandwise_report_dto.dart';

void main() {
  group('CounterBrandwiseReportDto', () {
    test('Category subtotal computation aggregates across manufacturers', () {
      final items = [
        const CounterBrandwiseReportItemDto(
          manufacturerName: 'United Breweries',
          openingBalance: BrandwiseSizeQty(beer650: 20, beer500Can: 10),
          purchase: BrandwiseSizeQty(beer650: 30),
          sale: BrandwiseSizeQty(beer650: 15, beer500Can: 4),
          closingBalance: BrandwiseSizeQty(beer650: 35, beer500Can: 6),
        ),
        const CounterBrandwiseReportItemDto(
          manufacturerName: 'AB InBev',
          openingBalance: BrandwiseSizeQty(beer650: 10, beer330Can: 12),
          purchase: BrandwiseSizeQty(beer330Can: 24),
          sale: BrandwiseSizeQty(beer650: 5, beer330Can: 6),
          closingBalance: BrandwiseSizeQty(beer650: 5, beer330Can: 30),
        ),
      ];

      final subtotal = CounterBrandwiseCategorySubtotal.compute(items);
      expect(subtotal.openingBalance.beer650, 30);
      expect(subtotal.openingBalance.beer500Can, 10);
      expect(subtotal.openingBalance.beer330Can, 12);
      expect(subtotal.purchase.beer650, 30);
      expect(subtotal.purchase.beer330Can, 24);
      expect(subtotal.sale.beer650, 20);
      expect(subtotal.sale.beer500Can, 4);
      expect(subtotal.sale.beer330Can, 6);
      expect(subtotal.closingBalance.beer650, 40);
      expect(subtotal.closingBalance.beer500Can, 6);
      expect(subtotal.closingBalance.beer330Can, 30);
    });

    test('CounterBrandwiseReportDto deserializes from JSON correctly', () {
      final json = {
        'reportDate': '2026-10-14T00:00:00.000',
        'licenseHeader': 'COUNTER BRANDWISE STOCK REPORT',
        'categories': [
          {
            'name': 'FERMENTED BEER',
            'items': [
              {
                'manufacturerName': 'Carlsberg India',
                'tpNo': 'TP-001',
                'openingBalance': {'beer650': 10},
                'purchase': {'beer650': 5},
                'sale': {'beer650': 3},
                'closingBalance': {'beer650': 12},
              }
            ],
            'subtotal': {
              'openingBalance': {'beer650': 10},
              'purchase': {'beer650': 5},
              'sale': {'beer650': 3},
              'closingBalance': {'beer650': 12},
            }
          }
        ]
      };

      final dto = CounterBrandwiseReportDto.fromJson(json);
      expect(dto.licenseHeader, 'COUNTER BRANDWISE STOCK REPORT');
      expect(dto.categories.length, 1);
      expect(dto.categories.first.name, 'FERMENTED BEER');
      expect(dto.categories.first.items.first.manufacturerName, 'Carlsberg India');
      expect(dto.categories.first.items.first.tpNo, 'TP-001');
      expect(dto.categories.first.items.first.openingBalance.beer650, 10);
      expect(dto.categories.first.items.first.sale.beer650, 3);
      expect(dto.categories.first.items.first.closingBalance.beer650, 12);
    });
  });
}
