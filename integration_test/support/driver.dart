import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/app.dart';
import 'package:pos_app/app/router.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/shared/widgets/inputs/app_dropdown.dart';
import 'package:pos_app/shared/widgets/inputs/app_text_field.dart';

/// One checklist step's automated outcome.
class StepResult {
  StepResult(this.id, this.status, this.note);
  final String id;
  final String status; // pass | fail | skip
  final String note;
  Map<String, String> toJson() => {'id': id, 'status': status, 'note': note};
}

/// Drives the real Caskly app the way a person would: types into labelled
/// fields, opens dropdowns, presses buttons and keys, and reads what the
/// screen and the database show. Records a result per checklist step
/// instead of stopping at the first failure.
class Driver {
  Driver(this.t);
  final WidgetTester t;
  final results = <StepResult>[];

  /// Flutter errors (overflows, crashes) seen while the app ran.
  final flutterErrors = <String>[];
  FlutterExceptionHandler? _savedOnError;

  /// Collect Flutter errors instead of failing the whole run at the first.
  void captureErrors() {
    _savedOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final first = details.exceptionAsString().split('\n').first;
      final where = details.context?.toDescription() ?? '';
      flutterErrors.add('$first ${where.isEmpty ? '' : '($where)'}'.trim());
    };
  }

  void restoreErrors() => FlutterError.onError = _savedOnError;

  ProviderContainer get c => ProviderScope.containerOf(t.element(find.byType(PosApp)));
  AppDatabase get db => c.read(appDatabaseProvider);

  // ── waiting ──────────────────────────────────────────────────────────

  /// Lets the app finish what it's doing (async saves, animations).
  Future<void> idle([int ms = 400]) async {
    for (var i = 0; i < 6; i++) {
      await t.pump(Duration(milliseconds: ms ~/ 6 + 1));
    }
    try {
      await t.pumpAndSettle(const Duration(milliseconds: 50), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 4));
    } catch (_) {
      // Something keeps animating (spinner, ticker); a fixed wait is enough.
      await t.pump(const Duration(milliseconds: 300));
    }
  }

  /// Real async work (DB writes on the real platform) needs real time.
  Future<void> wait(Duration d) async {
    await t.runAsync(() => Future<void>.delayed(d));
    await idle();
  }

  Future<void> until(bool Function() cond, {Duration timeout = const Duration(seconds: 10)}) async {
    final end = DateTime.now().add(timeout);
    while (!cond() && DateTime.now().isBefore(end)) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await t.pump(const Duration(milliseconds: 50));
    }
    await idle();
  }

  // ── navigation ───────────────────────────────────────────────────────

  Future<void> go(String route) async {
    c.read(appRouterProvider).go(route);
    await idle(600);
  }

  // ── finders ──────────────────────────────────────────────────────────

  Finder field(String label, {int index = 0}) {
    final host = find.byWidgetPredicate((w) => w is AppTextField && w.label == label);
    if (host.evaluate().length <= index) {
      final labels = find.byType(AppTextField).evaluate().map((e) => (e.widget as AppTextField).label).toList();
      throw StateError('no field "$label" on screen; fields: $labels');
    }
    return find.descendant(of: host.at(index), matching: find.byType(TextField));
  }

  /// An AppTextField found by its placeholder (search boxes have no label).
  Finder fieldHint(String hint) => find.descendant(
        of: find.byWidgetPredicate((w) => w is AppTextField && (w.hint ?? '').startsWith(hint)),
        matching: find.byType(TextField),
      );

  Future<void> search(String hint, String text) async {
    await t.tap(fieldHint(hint).first, warnIfMissed: false);
    await idle(100);
    await t.enterText(fieldHint(hint).first, text);
    await idle(300);
  }

  Finder dropdown(String label) => find.descendant(
        of: find.byWidgetPredicate((w) => w is AppDropdown && w.label == label),
        matching: find.byWidgetPredicate((w) => w is DropdownButton),
      );

  bool shows(String text) => find.text(text).evaluate().isNotEmpty;
  bool showsContaining(String text) => find.textContaining(text).evaluate().isNotEmpty;

  /// Text of every SnackBar currently on screen.
  String snacks() => find
      .descendant(of: find.byType(SnackBar), matching: find.byType(Text))
      .evaluate()
      .map((e) => (e.widget as Text).data ?? '')
      .join(' | ');

  /// Removes any message banners at once, so they can't cover the next tap.
  Future<void> clearSnacks() async {
    for (final e in find.byType(ScaffoldMessenger, skipOffstage: false).evaluate()) {
      final state = (e as StatefulElement).state;
      if (state is ScaffoldMessengerState) {
        state.clearSnackBars();
        state.removeCurrentSnackBar();
      }
    }
    await idle(200);
  }

  // ── actions ──────────────────────────────────────────────────────────

  Future<void> type(String label, String text, {int index = 0}) async {
    final f = field(label, index: index);
    expect(f, findsWidgets, reason: 'field "$label" not on screen');
    await t.ensureVisible(f.first);
    // Click into the box first, as a person does, then type. A window that
    // has just opened (or isn't in front yet) can miss the first try.
    for (var attempt = 0; attempt < 3 && textOf(f.first) != text; attempt++) {
      if (attempt > 0) await wait(const Duration(milliseconds: 500));
      await t.tap(f.first, warnIfMissed: false);
      await idle(100);
      await t.enterText(f.first, text);
      await idle(150);
    }
    if (textOf(f.first) != text) {
      throw StateError('typed "$text" into "$label" but it shows "${textOf(f.first)}"');
    }
  }

  Future<void> pick(String label, String item) async {
    final d = dropdown(label);
    expect(d, findsOneWidget, reason: 'dropdown "$label" not on screen');
    await t.ensureVisible(d);
    await t.tap(d);
    await idle(300);
    await t.tap(find.text(item).last);
    await idle(300);
  }

  Future<void> tapText(String text, {bool last = false}) async {
    final f = find.text(text);
    expect(f, findsWidgets, reason: '"$text" not on screen');
    final target = last ? f.last : f.first;
    await t.ensureVisible(target);
    await t.tap(target);
    await idle();
  }

  /// A desktop mouse click. The mouse is attached, clicks, then detached
  /// again, so later mouse gestures can attach it cleanly.
  Future<void> click(Finder f, {bool settle = true}) async {
    final at = t.getCenter(f);
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: at);
    await t.pump();
    await mouse.down(at);
    await mouse.up();
    await mouse.removePointer();
    if (settle) await idle();
  }

  /// Waits up to [timeout] for a message banner and returns its text as
  /// soon as it shows (banners vanish after 2 s; waiting to settle can miss
  /// them on screens that keep animating).
  Future<String> catchSnack({Duration timeout = const Duration(seconds: 4)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump(const Duration(milliseconds: 16));
      final s = snacks();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  Future<void> key(LogicalKeyboardKey k) async {
    await t.sendKeyEvent(k);
    await idle(200);
  }

  Future<void> enter() => key(LogicalKeyboardKey.enter);

  /// The text field that currently has keyboard focus.
  Finder get focused => find.byWidgetPredicate((w) => w is EditableText && w.focusNode.hasFocus);

  /// Types into the focused field (replacing its text), as a cashier does.
  Future<void> typeFocused(String text) async {
    expect(focused, findsOneWidget, reason: 'no text field has focus');
    await t.enterText(focused, text);
    await idle(150);
  }

  /// The text field showing [hint] as its placeholder.
  Finder hinted(String hint) =>
      find.byWidgetPredicate((w) => w is TextField && (w.decoration?.hintText ?? '').startsWith(hint));

  /// Text currently in the TextField found by [f].
  String textOf(Finder f) => (f.evaluate().first.widget as TextField).controller?.text ?? '';

  /// Saves a PNG of the whole app window (in the app's temp folder) and
  /// prints its path — for seeing what the screen showed at a failure.
  Future<String> snapshot(String name) async {
    final element = find.byType(PosApp).evaluate().first;
    final image = await captureImage(element);
    final bytes = await t.runAsync(() async => (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List());
    final file = File('${Directory.systemTemp.path}/e2e_$name.png');
    await t.runAsync(() => file.writeAsBytes(bytes!));
    // ignore: avoid_print
    print('E2E_SNAPSHOT ${file.path} size=${t.view.physicalSize}');
    return file.path;
  }

  // ── recording ────────────────────────────────────────────────────────

  /// Records step [id]. A thrown error inside [body] fails the step with
  /// its message; the run continues with the next step.
  Future<void> step(String id, String title, Future<String?> Function() body) async {
    String status, note;
    final errorsBefore = flutterErrors.length;
    try {
      final problem = await body();
      status = problem == null ? 'pass' : 'fail';
      note = problem ?? 'Automated: OK';
    } catch (e) {
      status = 'fail';
      note = 'Automated: ${e.toString().split('\n').take(4).join(' ')}';
    }
    if (status == 'fail') {
      try {
        note = '$note · screenshot ${await snapshot(id)}';
      } catch (_) {}
    }
    final newErrors = flutterErrors.skip(errorsBefore).toSet();
    if (newErrors.isNotEmpty) {
      status = 'fail';
      note = '$note · App error: ${newErrors.take(2).join(' / ')}';
    }
    results.add(StepResult(id, status, note));
    // ignore: avoid_print
    print('[${status.toUpperCase()}] $id $title${status == 'pass' ? '' : ' — $note'}');
    await clearSnacks();
  }

  void skip(String id, String why) {
    results.add(StepResult(id, 'skip', why));
    // ignore: avoid_print
    print('[SKIP] $id — $why');
  }

  /// Prints the results as one JSON line (the sandboxed app can't write
  /// into the project), and also tries [path].
  Future<void> writeReport(String path) async {
    final json = jsonEncode(results.map((r) => r.toJson()).toList());
    // ignore: avoid_print
    print('E2E_REPORT $json');
    try {
      await File(path).writeAsString(json);
    } catch (_) {}
  }
}
