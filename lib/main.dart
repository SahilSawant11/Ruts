import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/app.dart';
import 'core/logging/app_logger.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Fonts are bundled in assets/fonts — never reach out to the internet.
    GoogleFonts.config.allowRuntimeFetching = false;
    await AppLogger.init();
    AppLogger.info('App', 'Caskly starting');
    runApp(const ProviderScope(child: PosApp()));
  }, (error, stack) => AppLogger.error('Zone', error, stack));
}
