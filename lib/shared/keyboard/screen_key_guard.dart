import 'package:flutter/widgets.dart';

/// Screen-level shortcuts registered with `HardwareKeyboard` fire app-wide,
/// even for screens kept alive in the background by the shell's
/// IndexedStack. Call this first in such a handler: it is true only when
/// [context]'s screen is the visible one and no dialog/menu has focus.
///
/// Without it, pressing Esc to close a dialog on another screen would also
/// clear the sales bill, and F8 elsewhere would try to save it.
bool screenOwnsKeyboard(BuildContext context) {
  if (!context.mounted) return false;
  // Inactive shell branches are wrapped in TickerMode(enabled: false).
  if (!TickerMode.valuesOf(context).enabled) return false;
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused != null && ModalRoute.of(focused) is PopupRoute) return false;
  return true;
}
