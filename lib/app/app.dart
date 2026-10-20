import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/auth/auth_controller.dart';
import '../core/local/app_bootstrap_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/font_scale_provider.dart';
import '../core/theme/theme_mode_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import 'router.dart';

class PosApp extends ConsumerWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapAsync = ref.watch(appBootstrapProvider);
    final auth = ref.watch(authControllerProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final fontScale = ref.watch(appFontScaleProvider);

    Widget appBuilder(BuildContext context, Widget? child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(fontScale),
        ),
        child: child ?? const SizedBox.shrink(),
      );
    }

    if (bootstrapAsync.isLoading || auth.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        builder: appBuilder,
        home: const _BootstrapScreen(),
      );
    }

    if (bootstrapAsync.hasError) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        builder: appBuilder,
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

    if (!auth.isAuthenticated) {
      return MaterialApp(
        title: 'Caskly - Liquor Store POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        builder: appBuilder,
        home: const LoginScreen(),
      );
    }

    return MaterialApp.router(
      title: 'Caskly - Liquor Store POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      builder: appBuilder,
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
            Text('Preparing Caskly...'),
          ],
        ),
      ),
    );
  }
}
