import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/format/money.dart';
import 'package:pos_app/shared/keyboard/screen_key_guard.dart';

void main() {
  group('Money (Indian grouping)', () {
    test('formats lakhs and crores', () {
      expect(Money.inr(0), '₹0.00');
      expect(Money.inr(999), '₹999.00');
      expect(Money.inr(5991.6), '₹5,991.60');
      expect(Money.inr(123456.789), '₹1,23,456.79');
      expect(Money.inr(12345678), '₹1,23,45,678.00');
      expect(Money.inr(-1500), '-₹1,500.00');
      expect(Money.plain(1290), '1,290.00');
      expect(Money.inr(100000, decimals: 0), '₹1,00,000');
      expect(Money.compact(950), '₹950');
      expect(Money.compact(111000), '₹1.11 L');
      expect(Money.compact(30000000), '₹3 Cr');
      expect(Money.editable(1180.0), '1180');
      expect(Money.editable(18.5), '18.5');
      expect(Money.editable(12.345), '12.35');
    });
  });

  group('screenOwnsKeyboard', () {
    testWidgets('false for a background (TickerMode off) screen, true when visible', (tester) async {
      late BuildContext visible;
      late BuildContext hidden;
      await tester.pumpWidget(MaterialApp(
        home: Column(children: [
          Builder(builder: (c) {
            visible = c;
            return const SizedBox();
          }),
          TickerMode(
            enabled: false,
            child: Builder(builder: (c) {
              hidden = c;
              return const SizedBox();
            }),
          ),
        ]),
      ));
      expect(screenOwnsKeyboard(visible), isTrue);
      expect(screenOwnsKeyboard(hidden), isFalse);
    });

    testWidgets('false while a dialog has focus', (tester) async {
      late BuildContext screen;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (c) {
          screen = c;
          return const Scaffold();
        }),
      ));
      showDialog<void>(context: screen, builder: (_) => const AlertDialog(content: TextField(autofocus: true)));
      await tester.pumpAndSettle();
      expect(screenOwnsKeyboard(screen), isFalse);
    });
  });
}
