import 'brandwise_report_dto.dart';

/// One row in the counter brandwise register — a single manufacturer
/// with all its brands' quantities aggregated into 4 balance blocks.
class CounterBrandwiseReportItemDto {
  const CounterBrandwiseReportItemDto({
    required this.manufacturerName,
    this.tpNo,
    required this.openingBalance,
    required this.purchase,
    required this.sale,
    required this.closingBalance,
  });

  final String manufacturerName;
  final String? tpNo;
  final BrandwiseSizeQty openingBalance;
  final BrandwiseSizeQty purchase;
  final BrandwiseSizeQty sale;
  final BrandwiseSizeQty closingBalance;

  factory CounterBrandwiseReportItemDto.fromJson(Map<String, dynamic> json) {
    return CounterBrandwiseReportItemDto(
      manufacturerName: json['manufacturerName'] as String,
      tpNo: json['tpNo'] as String?,
      openingBalance: BrandwiseSizeQty.fromJson(json['openingBalance'] as Map<String, dynamic>),
      purchase: BrandwiseSizeQty.fromJson(json['purchase'] as Map<String, dynamic>),
      sale: BrandwiseSizeQty.fromJson(json['sale'] as Map<String, dynamic>),
      closingBalance: BrandwiseSizeQty.fromJson(json['closingBalance'] as Map<String, dynamic>),
    );
  }
}

/// A product category section (Fermented Beer / Mild Beer / Wine)
/// with its list of manufacturer rows and computed subtotals.
class CounterBrandwiseCategoryDto {
  const CounterBrandwiseCategoryDto({
    required this.name,
    required this.items,
    required this.subtotal,
  });

  final String name;
  final List<CounterBrandwiseReportItemDto> items;
  final CounterBrandwiseCategorySubtotal subtotal;

  factory CounterBrandwiseCategoryDto.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    final items = itemsJson
        .map((e) => CounterBrandwiseReportItemDto.fromJson(e as Map<String, dynamic>))
        .toList();

    CounterBrandwiseCategorySubtotal subtotal;
    if (json['subtotal'] != null) {
      subtotal = CounterBrandwiseCategorySubtotal.fromJson(json['subtotal'] as Map<String, dynamic>);
    } else {
      subtotal = CounterBrandwiseCategorySubtotal.compute(items);
    }

    return CounterBrandwiseCategoryDto(name: json['name'] as String, items: items, subtotal: subtotal);
  }
}

/// Subtotals for a category section.
class CounterBrandwiseCategorySubtotal {
  const CounterBrandwiseCategorySubtotal({
    required this.openingBalance,
    required this.purchase,
    required this.sale,
    required this.closingBalance,
  });

  final BrandwiseSizeQty openingBalance;
  final BrandwiseSizeQty purchase;
  final BrandwiseSizeQty sale;
  final BrandwiseSizeQty closingBalance;

  factory CounterBrandwiseCategorySubtotal.compute(List<CounterBrandwiseReportItemDto> items) {
    var ob = BrandwiseSizeQty.zero;
    var pu = BrandwiseSizeQty.zero;
    var sa = BrandwiseSizeQty.zero;
    var cb = BrandwiseSizeQty.zero;
    for (final item in items) {
      ob = ob + item.openingBalance;
      pu = pu + item.purchase;
      sa = sa + item.sale;
      cb = cb + item.closingBalance;
    }
    return CounterBrandwiseCategorySubtotal(openingBalance: ob, purchase: pu, sale: sa, closingBalance: cb);
  }

  factory CounterBrandwiseCategorySubtotal.fromJson(Map<String, dynamic> json) {
    return CounterBrandwiseCategorySubtotal(
      openingBalance: BrandwiseSizeQty.fromJson(json['openingBalance'] as Map<String, dynamic>),
      purchase: BrandwiseSizeQty.fromJson(json['purchase'] as Map<String, dynamic>),
      sale: BrandwiseSizeQty.fromJson(json['sale'] as Map<String, dynamic>),
      closingBalance: BrandwiseSizeQty.fromJson(json['closingBalance'] as Map<String, dynamic>),
    );
  }
}

/// Top-level report.
class CounterBrandwiseReportDto {
  const CounterBrandwiseReportDto({
    required this.reportDate,
    required this.licenseHeader,
    required this.categories,
  });

  final DateTime reportDate;
  final String licenseHeader;
  final List<CounterBrandwiseCategoryDto> categories;

  factory CounterBrandwiseReportDto.fromJson(Map<String, dynamic> json) {
    final cats = (json['categories'] as List<dynamic>? ?? const [])
        .map((e) => CounterBrandwiseCategoryDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return CounterBrandwiseReportDto(
      reportDate: DateTime.parse(json['reportDate'] as String),
      licenseHeader: (json['licenseHeader'] as String?) ?? 'COUNTER BRANDWISE STOCK REPORT',
      categories: cats,
    );
  }
}
