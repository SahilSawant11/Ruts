import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/app.dart';
import 'package:pos_app/core/local/app_bootstrap_provider.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appBootstrapProvider.overrideWith((ref) async {}),
        ],
        child: const PosApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(PosApp), findsOneWidget);
  });
}
