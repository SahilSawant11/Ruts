import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the left sidebar is showing full labels (false) or collapsed
/// to an icon-only rail (true). Toggled by the hamburger button in the
/// top header, read by the sidebar to decide its width/content.
final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);
