import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/masters/data/masters_providers.dart';

final appBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.watch(appDatabaseProvider).ensureStarterData();
});
