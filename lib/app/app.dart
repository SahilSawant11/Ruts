import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/local/app_bootstrap_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_provider.dart';
import 'router.dart';

class PosApp extends ConsumerWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapAsync = ref.watch(appBootstrapProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    if (bootstrapAsync.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: const _BootstrapScreen(),
      );
    }

    if (bootstrapAsync.hasError) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not prepare offline starter data.\n${bootstrapAsync.error}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Caskly - Liquor Store POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 16),
            Text('Preparing offline store data...'),
          ],
        ),
      ),
    );
  }
}
