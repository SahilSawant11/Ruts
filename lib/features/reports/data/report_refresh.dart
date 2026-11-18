import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'brandwise_report_provider.dart';
import 'counter_brandwise_report_provider.dart';
import 'reports_providers.dart';

/// Drops every cached stock / sales report so the next look rebuilds it.
/// Call after anything that changes stock: a sale, purchase or return.
/// Pass `ref.invalidate` (works for both `Ref` and `WidgetRef`).
void refreshStockReports(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(brandwiseReportProvider);
  invalidate(counterBrandwiseReportProvider);
  invalidate(salesReportProvider);
  invalidate(licenseHolderReportProvider);
}
