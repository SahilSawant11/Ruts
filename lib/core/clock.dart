import 'package:flutter/foundation.dart';

/// The app's "now" for business dates (bill dates, returns, bill-number
/// year, default report day). Always the real time in the app; tests can
/// set [override] to replay several shop days in seconds.
class AppClock {
  AppClock._();

  static DateTime Function()? _override;

  static DateTime now() => _override?.call() ?? DateTime.now();

  @visibleForTesting
  static set override(DateTime Function()? f) => _override = f;
}
