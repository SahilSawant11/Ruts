import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:win32_registry/win32_registry.dart';

import '../local/db_paths.dart';
import 'license_codec.dart';

/// A stable, privacy-preserving id for this computer, shown to the store
/// as XXXX-XXXX-XXXX-XXXX and used to lock the license to this machine.
///
/// Windows: HKLM\SOFTWARE\Microsoft\Cryptography\MachineGuid (changes only
/// when Windows is reinstalled). macOS: IOPlatformUUID. Linux: /etc/machine-id.
/// If none can be read, a random id is generated and kept in app data.
abstract final class MachineId {
  static String? _cached;

  static Future<String> get() async {
    if (_cached != null) return _cached!;
    final raw = await _raw() ?? await _fallback();
    final digest = await Sha256().hash(utf8.encode('caskly-machine-v1|$raw'));
    final hex = digest.bytes.take(8).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return _cached = LicenseCodec.normaliseMachineId(hex);
  }

  static Future<String?> _raw() async {
    try {
      if (Platform.isWindows) {
        final key = LOCAL_MACHINE.open(r'SOFTWARE\Microsoft\Cryptography');
        try {
          return key.getString('MachineGuid');
        } finally {
          key.close();
        }
      }
      if (Platform.isMacOS) {
        final r = await Process.run('/usr/sbin/ioreg', ['-rd1', '-c', 'IOPlatformExpertDevice']);
        final m = RegExp(r'"IOPlatformUUID"\s*=\s*"([^"]+)"').firstMatch('${r.stdout}');
        return m?.group(1);
      }
      if (Platform.isLinux) {
        for (final path in const ['/etc/machine-id', '/var/lib/dbus/machine-id']) {
          final f = File(path);
          if (await f.exists()) return (await f.readAsString()).trim();
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String> _fallback() async {
    final f = File(DbPaths.join((await DbPaths.root()).path, 'machine.id'));
    if (await f.exists()) return f.readAsString();
    final id = DbPaths.newId();
    await f.writeAsString(id);
    return id;
  }
}
