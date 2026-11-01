// Pure Dart (no Flutter imports) so tooling/license_tool.dart can share it.
import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// A signed Caskly license.
///
/// Key format: `CASKLY1.<base64url payload>.<base64url ed25519 signature>`
class LicenseData {
  const LicenseData({
    required this.licenseId,
    required this.licensedTo,
    required this.machineId,
    required this.issuedAt,
    this.expiresAt,
    this.edition = 'standard',
  });

  final String licenseId;
  final String licensedTo;
  final String machineId;
  final DateTime issuedAt;

  /// Null = perpetual.
  final DateTime? expiresAt;
  final String edition;

  Map<String, dynamic> toJson() => {
        'v': 1,
        'lic': licenseId,
        'to': licensedTo,
        'mid': machineId,
        'iat': _date(issuedAt),
        if (expiresAt != null) 'exp': _date(expiresAt!),
        'ed': edition,
      };

  factory LicenseData.fromJson(Map<String, dynamic> j) => LicenseData(
        licenseId: j['lic'] as String,
        licensedTo: j['to'] as String,
        machineId: j['mid'] as String,
        issuedAt: DateTime.parse(j['iat'] as String),
        expiresAt: j['exp'] == null ? null : DateTime.parse(j['exp'] as String),
        edition: (j['ed'] as String?) ?? 'standard',
      );

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

abstract final class LicenseCodec {
  static const prefix = 'CASKLY1';
  static final _algo = Ed25519();

  static Future<String> sign(LicenseData data, SimpleKeyPair keyPair) async {
    final payload = utf8.encode(jsonEncode(data.toJson()));
    final sig = await _algo.sign(payload, keyPair: keyPair);
    return '$prefix.${_b64(payload)}.${_b64(sig.bytes)}';
  }

  /// Returns the license if [key] is well-formed and correctly signed by
  /// [publicKeyB64]; otherwise null. Does NOT check machine or expiry.
  static Future<LicenseData?> verify(String key, String publicKeyB64) async {
    try {
      final parts = key.trim().replaceAll(RegExp(r'\s+'), '').split('.');
      if (parts.length != 3 || parts[0] != prefix) return null;
      final payload = _unb64(parts[1]);
      final sig = _unb64(parts[2]);
      final publicKey = SimplePublicKey(base64Decode(publicKeyB64), type: KeyPairType.ed25519);
      final ok = await _algo.verify(payload, signature: Signature(sig, publicKey: publicKey));
      if (!ok) return null;
      return LicenseData.fromJson(jsonDecode(utf8.decode(payload)) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Normalises a machine id the way it is printed: XXXX-XXXX-XXXX-XXXX.
  static String normaliseMachineId(String raw) {
    final hex = raw.toUpperCase().replaceAll(RegExp('[^0-9A-F]'), '');
    final buf = StringBuffer();
    for (var i = 0; i < hex.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write('-');
      buf.write(hex[i]);
    }
    return buf.toString();
  }

  static String _b64(List<int> b) => base64Url.encode(b).replaceAll('=', '');
  static List<int> _unb64(String s) => base64Url.decode(s.padRight((s.length + 3) ~/ 4 * 4, '='));
}
