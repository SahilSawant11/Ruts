import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Function keys F1-F12 are defined logical keyboard keys', () {
    const expectedKeys = [
      LogicalKeyboardKey.f1,
      LogicalKeyboardKey.f2,
      LogicalKeyboardKey.f3,
      LogicalKeyboardKey.f4,
      LogicalKeyboardKey.f5,
      LogicalKeyboardKey.f6,
      LogicalKeyboardKey.f7,
      LogicalKeyboardKey.f8,
      LogicalKeyboardKey.f9,
      LogicalKeyboardKey.f10,
      LogicalKeyboardKey.f11,
      LogicalKeyboardKey.f12,
    ];

    for (final key in expectedKeys) {
      expect(key.keyId, isNotNull);
    }
  });

  test('HardwareKeyboard event dispatch simulation for function keys', () {
    final detected = <LogicalKeyboardKey>[];

    bool handler(KeyEvent event) {
      if (event is! KeyDownEvent) return false;
      detected.add(event.logicalKey);
      return true;
    }

    const f2Event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.f2,
      logicalKey: LogicalKeyboardKey.f2,
      timeStamp: Duration.zero,
    );
    expect(handler(f2Event), isTrue);
    expect(detected, contains(LogicalKeyboardKey.f2));

    const f3Event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.f3,
      logicalKey: LogicalKeyboardKey.f3,
      timeStamp: Duration.zero,
    );
    expect(handler(f3Event), isTrue);
    expect(detected, contains(LogicalKeyboardKey.f3));

    const f8Event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.f8,
      logicalKey: LogicalKeyboardKey.f8,
      timeStamp: Duration.zero,
    );
    expect(handler(f8Event), isTrue);
    expect(detected, contains(LogicalKeyboardKey.f8));

    const escEvent = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.escape,
      logicalKey: LogicalKeyboardKey.escape,
      timeStamp: Duration.zero,
    );
    expect(handler(escEvent), isTrue);
    expect(detected, contains(LogicalKeyboardKey.escape));
  });
}
