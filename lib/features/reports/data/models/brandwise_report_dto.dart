/// Quantities broken out by bottle-size column, matching the excise
/// register's 7 physical columns (3 wine + 4 beer).
class BrandwiseSizeQty {
  const BrandwiseSizeQty({
    this.wine750 = 0,
    this.wine375 = 0,
    this.wine180 = 0,
    this.beer650 = 0,
    this.beer500Can = 0,
    this.beer330Can = 0,
    this.beer330Bottle = 0,
  });

  final int wine750;
  final int wine375;
  final int wine180;
  final int beer650;
  final int beer500Can;
  final int beer330Can;
  final int beer330Bottle;

  int get total => wine750 + wine375 + wine180 + beer650 + beer500Can + beer330Can + beer330Bottle;

  /// Returns the value for a given column index (0–6).
  int byIndex(int index) => switch (index) {
        0 => wine750,
        1 => wine375,
        2 => wine180,
        3 => beer650,
        4 => beer500Can,
        5 => beer330Can,
        6 => beer330Bottle,
        _ => 0,
      };

  BrandwiseSizeQty operator +(BrandwiseSizeQty other) => BrandwiseSizeQty(
        wine750: wine750 + other.wine750,
        wine375: wine375 + other.wine375,
        wine180: wine180 + other.wine180,
        beer650: beer650 + other.beer650,
        beer500Can: beer500Can + other.beer500Can,
        beer330Can: beer330Can + other.beer330Can,
        beer330Bottle: beer330Bottle + other.beer330Bottle,
      );

  factory BrandwiseSizeQty.fromJson(Map<String, dynamic> json) {
    return BrandwiseSizeQty(
      wine750: (json['wine750'] as num?)?.toInt() ?? 0,
      wine375: (json['wine375'] as num?)?.toInt() ?? 0,
      wine180: (json['wine180'] as num?)?.toInt() ?? 0,
      beer650: (json['beer650'] as num?)?.toInt() ?? 0,
      beer500Can: (json['beer500Can'] as num?)?.toInt() ?? 0,
      beer330Can: (json['beer330Can'] as num?)?.toInt() ?? 0,
      beer330Bottle: (json['beer330Bottle'] as num?)?.toInt() ?? 0,
    );
  }

  static const zero = BrandwiseSizeQty();
}

/// One row in the register — a single brand + its 4 quantity blocks.
class BrandwiseReportItemDto {
  const BrandwiseReportItemDto({
    required this.brandName,
    this.tpNo,
    required this.openingBalance,
    required this.purchase,
    required this.sale,
    required this.closingBalance,
  });

  final String brandName;
  final String? tpNo;
  final BrandwiseSizeQty openingBalance;
  final BrandwiseSizeQty purchase;
  final BrandwiseSizeQty sale;
  final BrandwiseSizeQty closingBalance;

  factory BrandwiseReportItemDto.fromJson(Map<String, dynamic> json) {
    return BrandwiseReportItemDto(
      brandName: json['brandName'] as String,
      tpNo: json['tpNo'] as String?,
      openingBalance: BrandwiseSizeQty.fromJson(json['openingBalance'] as Map<String, dynamic>),
      purchase: BrandwiseSizeQty.fromJson(json['purchase'] as Map<String, dynamic>),
      sale: BrandwiseSizeQty.fromJson(json['sale'] as Map<String, dynamic>),
      closingBalance: BrandwiseSizeQty.fromJson(json['closingBalance'] as Map<String, dynamic>),
    );
  }
}

/// A product category section (Fermented Beer / Mild Beer / Wine)
/// with its list of brand rows and computed subtotals.
class BrandwiseCategoryDto {
  const BrandwiseCategoryDto({
    required this.name,
    required this.items,
    required this.subtotal,
  });

  final String name;
  final List<BrandwiseReportItemDto> items;
  final BrandwiseCategorySubtotal subtotal;

  factory BrandwiseCategoryDto.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    final items = itemsJson
        .map((e) => BrandwiseReportItemDto.fromJson(e as Map<String, dynamic>))
        .toList();

    BrandwiseCategorySubtotal subtotal;
    if (json['subtotal'] != null) {
      subtotal = BrandwiseCategorySubtotal.fromJson(json['subtotal'] as Map<String, dynamic>);
    } else {
      subtotal = BrandwiseCategorySubtotal.compute(items);
    }

    return BrandwiseCategoryDto(name: json['name'] as String, items: items, subtotal: subtotal);
  }
}

/// Subtotals for a category section.
class BrandwiseCategorySubtotal {
  const BrandwiseCategorySubtotal({
    required this.openingBalance,
    required this.purchase,
    required this.sale,
    required this.closingBalance,
  });

  final BrandwiseSizeQty openingBalance;
  final BrandwiseSizeQty purchase;
  final BrandwiseSizeQty sale;
  final BrandwiseSizeQty closingBalance;

  factory BrandwiseCategorySubtotal.compute(List<BrandwiseReportItemDto> items) {
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
    return BrandwiseCategorySubtotal(openingBalance: ob, purchase: pu, sale: sa, closingBalance: cb);
  }

  factory BrandwiseCategorySubtotal.fromJson(Map<String, dynamic> json) {
    return BrandwiseCategorySubtotal(
      openingBalance: BrandwiseSizeQty.fromJson(json['openingBalance'] as Map<String, dynamic>),
      purchase: BrandwiseSizeQty.fromJson(json['purchase'] as Map<String, dynamic>),
      sale: BrandwiseSizeQty.fromJson(json['sale'] as Map<String, dynamic>),
      closingBalance: BrandwiseSizeQty.fromJson(json['closingBalance'] as Map<String, dynamic>),
    );
  }
}

/// Top-level report.
class BrandwiseReportDto {
  const BrandwiseReportDto({
    required this.reportDate,
    required this.licenseHeader,
    required this.categories,
  });

  final DateTime reportDate;
  final String licenseHeader;
  final List<BrandwiseCategoryDto> categories;

  factory BrandwiseReportDto.fromJson(Map<String, dynamic> json) {
    final cats = (json['categories'] as List<dynamic>? ?? const [])
        .map((e) => BrandwiseCategoryDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return BrandwiseReportDto(
      reportDate: DateTime.parse(json['reportDate'] as String),
      licenseHeader: (json['licenseHeader'] as String?) ?? 'BEER A : WINE BR. II BRANDWISE STOCK REPORT',
      categories: cats,
    );
  }
}
