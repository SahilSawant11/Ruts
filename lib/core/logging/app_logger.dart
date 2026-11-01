import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../local/db_paths.dart';

/// Writes errors and key events to daily log files so support can see
/// what happened on a client's machine:
///   %APPDATA%\Caskly\Caskly POS\caskly\logs\caskly-2026-11-01.log
/// Keeps the last [keepDays] days.
abstract final class AppLogger {
  static const keepDays = 14;
  static IOSink? _sink;
  static String? _currentDay;
  static Directory? _dir;

  // Collapse bursts of the same message (e.g. a layout error repeated every
  // frame) into one line plus a "repeated N times" note.
  static String? _lastKey;
  static DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);
  static int _repeats = 0;
  static const _repeatWindow = Duration(seconds: 30);

  static Future<void> init() async {
    try {
      _dir = await DbPaths.logsDir();
      await _prune();
    } catch (e) {
      debugPrint('Logger init failed: $e');
    }

    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      error('Flutter', details.exceptionAsString(), details.stack);
      previousOnError?.call(details);
    };
    WidgetsBinding.instance.platformDispatcher.onError = (e, st) {
      error('Platform', e, st);
      return true;
    };
  }

  static void info(String area, String message) => _write('INFO', area, message);
  static void warn(String area, String message) => _write('WARN', area, message);

  static void error(String area, Object error, [StackTrace? stack]) {
    _write('ERROR', area, '$error${stack == null ? '' : '\n$stack'}');
  }

  static Future<Directory?> directory() async => _dir ?? await DbPaths.logsDir();

  static void _write(String level, String area, String message) {
    final now = DateTime.now();
    final key = '$level|$area|${message.split('\n').first}';
    if (key == _lastKey && now.difference(_lastAt) < _repeatWindow) {
      _repeats++;
      return;
    }
    if (_repeats > 0) {
      final repeated = _repeats;
      _repeats = 0;
      _emit(now, 'INFO', 'Logger', 'previous message repeated $repeated more time(s)');
    }
    _lastKey = key;
    _lastAt = now;
    _emit(now, level, area, message);
  }

  static void _emit(DateTime now, String level, String area, String message) {
    final line = '${now.toIso8601String()} [$level] $area: $message';
    if (kDebugMode) debugPrint(line);
    final dir = _dir;
    if (dir == null) return;
    try {
      final day = now.toIso8601String().substring(0, 10);
      if (_currentDay != day || _sink == null) {
        unawaited(_sink?.close());
        _sink = File(DbPaths.join(dir.path, 'caskly-$day.log')).openWrite(mode: FileMode.append);
        _currentDay = day;
      }
      _sink!.writeln(line);
    } catch (_) {
      // Logging must never crash the till.
    }
  }

  static Future<void> _prune() async {
    final dir = _dir;
    if (dir == null) return;
    final cutoff = DateTime.now().subtract(const Duration(days: keepDays));
    await for (final e in dir.list()) {
      if (e is File && e.path.endsWith('.log') && (await e.stat()).modified.isBefore(cutoff)) {
        try {
          await e.delete();
        } catch (_) {}
      }
    }
  }
}
