import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/logging/app_logger.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await AppLogger.init();
    AppLogger.info('App', 'Caskly starting');
    runApp(const ProviderScope(child: PosApp()));
  }, (error, stack) => AppLogger.error('Zone', error, stack));
}
