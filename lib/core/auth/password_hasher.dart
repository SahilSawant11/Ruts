import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// PBKDF2-HMAC-SHA256 password hashing.
/// Stored format: `pbkdf2-sha256$<iterations>$<saltB64>$<hashB64>`.
/// The iteration count travels with the hash, so it can be raised later
/// without breaking existing passwords.
abstract final class PasswordHasher {
  static int iterations = 60000;
  static final _rng = Random.secure();

  static Future<String> hash(String password, {int? iterations}) async {
    final iters = iterations ?? PasswordHasher.iterations;
    final salt = List<int>.generate(16, (_) => _rng.nextInt(256));
    final bytes = await _derive(password, salt, iters);
    return 'pbkdf2-sha256\$$iters\$${base64Encode(salt)}\$${base64Encode(bytes)}';
  }

  static Future<bool> verify(String password, String stored) async {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != 'pbkdf2-sha256') return false;
    final iters = int.tryParse(parts[1]);
    if (iters == null) return false;
    final salt = base64Decode(parts[2]);
    final expected = base64Decode(parts[3]);
    final actual = await _derive(password, salt, iters);
    if (actual.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual[i] ^ expected[i];
    }
    return diff == 0;
  }

  static Future<List<int>> _derive(String password, List<int> salt, int iters) async {
    final algo = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iters, bits: 256);
    final key = await algo.deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
    return key.extractBytes();
  }
}
