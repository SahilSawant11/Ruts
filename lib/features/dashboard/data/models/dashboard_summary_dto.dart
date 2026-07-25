class DailyTrendPointDto {
  const DailyTrendPointDto({required this.date, required this.amount});
  final DateTime date;
  final double amount;

  factory DailyTrendPointDto.fromJson(Map<String, dynamic> json) => DailyTrendPointDto(
        date: DateTime.parse(json['date'] as String),
        amount: (json['amount'] as num).toDouble(),
      );
}

class CategoryBreakdownItemDto {
  const CategoryBreakdownItemDto({required this.category, required this.amount});
  final String category;
  final double amount;

  factory CategoryBreakdownItemDto.fromJson(Map<String, dynamic> json) => CategoryBreakdownItemDto(
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
      );
}

class PaymentMixItemDto {
  const PaymentMixItemDto({required this.payMode, required this.amount, required this.percent});
  final String payMode;
  final double amount;
  final double percent;

  factory PaymentMixItemDto.fromJson(Map<String, dynamic> json) => PaymentMixItemDto(
        payMode: json['payMode'] as String,
        amount: (json['amount'] as num).toDouble(),
        percent: (json['percent'] as num).toDouble(),
      );
}

class TopSellingItemDto {
  const TopSellingItemDto({required this.materialName, this.packing, required this.qty, required this.amount});
  final String materialName;
  final String? packing;
  final int qty;
  final double amount;

  factory TopSellingItemDto.fromJson(Map<String, dynamic> json) => TopSellingItemDto(
        materialName: json['materialName'] as String,
        packing: json['packing'] as String?,
        qty: json['qty'] as int,
        amount: (json['amount'] as num).toDouble(),
      );
}

class RecentTransactionDto {
  const RecentTransactionDto({
    required this.billNo,
    required this.billDate,
    required this.customerName,
    required this.payMode,
    required this.totalAmount,
    required this.status,
  });

  final String billNo;
  final DateTime billDate;
  final String customerName;
  final String payMode;
  final double totalAmount;
  final String status;

  factory RecentTransactionDto.fromJson(Map<String, dynamic> json) => RecentTransactionDto(
        billNo: json['billNo'] as String,
        billDate: DateTime.parse(json['billDate'] as String),
        customerName: json['customerName'] as String,
        payMode: json['payMode'] as String,
        totalAmount: (json['totalAmount'] as num).toDouble(),
        status: json['status'] as String,
      );
}

class TopCustomerDto {
  const TopCustomerDto({required this.customerName, required this.billCount, required this.totalAmount});
  final String customerName;
  final int billCount;
  final double totalAmount;

  factory TopCustomerDto.fromJson(Map<String, dynamic> json) => TopCustomerDto(
        customerName: json['customerName'] as String,
        billCount: json['billCount'] as int,
        totalAmount: (json['totalAmount'] as num).toDouble(),
      );
}

/// Full GET /api/dashboard/summary response.
class DashboardSummaryDto {
  const DashboardSummaryDto({
    required this.todaySales,
    required this.todayBillCount,
    required this.avgBillValue,
    this.salesDeltaPercent,
    this.billsDeltaPercent,
    required this.dailyTarget,
    required this.last7Days,
    required this.categoryBreakdown,
    required this.paymentMix,
    required this.topSellingItems,
    required this.recentTransactions,
    required this.topCustomers,
  });

  final double todaySales;
  final int todayBillCount;
  final double avgBillValue;
  final double? salesDeltaPercent;
  final double? billsDeltaPercent;
  final double dailyTarget;
  final List<DailyTrendPointDto> last7Days;
  final List<CategoryBreakdownItemDto> categoryBreakdown;
  final List<PaymentMixItemDto> paymentMix;
  final List<TopSellingItemDto> topSellingItems;
  final List<RecentTransactionDto> recentTransactions;
  final List<TopCustomerDto> topCustomers;

  factory DashboardSummaryDto.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final list = json[key] as List<dynamic>? ?? const [];
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }

    return DashboardSummaryDto(
      todaySales: (json['todaySales'] as num).toDouble(),
      todayBillCount: json['todayBillCount'] as int,
      avgBillValue: (json['avgBillValue'] as num).toDouble(),
      salesDeltaPercent: (json['salesDeltaPercent'] as num?)?.toDouble(),
      billsDeltaPercent: (json['billsDeltaPercent'] as num?)?.toDouble(),
      dailyTarget: (json['dailyTarget'] as num).toDouble(),
      last7Days: parseList('last7Days', DailyTrendPointDto.fromJson),
      categoryBreakdown: parseList('categoryBreakdown', CategoryBreakdownItemDto.fromJson),
      paymentMix: parseList('paymentMix', PaymentMixItemDto.fromJson),
      topSellingItems: parseList('topSellingItems', TopSellingItemDto.fromJson),
      recentTransactions: parseList('recentTransactions', RecentTransactionDto.fromJson),
      topCustomers: parseList('topCustomers', TopCustomerDto.fromJson),
    );
  }
}
