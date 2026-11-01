// Caskly license tool — run on YOUR machine only, never ship it.
//
//   dart run tooling/license_tool.dart keygen
//       Creates the signing key pair in ~/.caskly-keys/ (once, ever).
//       Paste the printed public key into lib/core/licensing/license_keys.dart.
//
//   dart run tooling/license_tool.dart issue --machine A1B2-C3D4-E5F6-0718 --to "Store Name" [--expires 2027-11-30]
//       Prints a license key for that machine. The store sees its Machine ID
//       on the activation screen.
//
// KEEP ~/.caskly-keys/license_private.key SAFE AND BACKED UP. Anyone with it
// can issue licenses; if you lose it, you can't issue licenses for the
// current app builds.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:pos_app/core/licensing/license_codec.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) return _usage();
  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE']!;
  final dir = Directory('$home${Platform.pathSeparator}.caskly-keys');
  final privFile = File('${dir.path}${Platform.pathSeparator}license_private.key');

  switch (args.first) {
    case 'keygen':
      if (privFile.existsSync()) {
        stderr.writeln('Refusing to overwrite existing key: ${privFile.path}');
        exit(1);
      }
      dir.createSync(recursive: true);
      final kp = await Ed25519().newKeyPair();
      final seed = await kp.extractPrivateKeyBytes();
      final pub = await kp.extractPublicKey();
      privFile.writeAsStringSync(base64Encode(seed));
      if (!Platform.isWindows) Process.runSync('chmod', ['600', privFile.path]);
      stdout.writeln('Private key saved: ${privFile.path}');
      stdout.writeln('Public key (put in license_keys.dart):\n${base64Encode(pub.bytes)}');
    case 'issue':
      final opts = _parse(args.skip(1).toList());
      final machine = opts['machine'];
      final to = opts['to'];
      if (machine == null || to == null) return _usage();
      if (!privFile.existsSync()) {
        stderr.writeln('No private key. Run keygen first.');
        exit(1);
      }
      final kp = await Ed25519().newKeyPairFromSeed(base64Decode(privFile.readAsStringSync().trim()));
      final rnd = Random.secure();
      final data = LicenseData(
        licenseId: List.generate(6, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join().toUpperCase(),
        licensedTo: to,
        machineId: LicenseCodec.normaliseMachineId(machine),
        issuedAt: DateTime.now(),
        expiresAt: opts['expires'] == null ? null : DateTime.parse(opts['expires']!),
      );
      final key = await LicenseCodec.sign(data, kp);
      stdout.writeln('License ${data.licenseId} for "${data.licensedTo}" on ${data.machineId}'
          '${data.expiresAt == null ? ' (perpetual)' : ' until ${opts['expires']}'}:\n');
      stdout.writeln(key);
    default:
      _usage();
  }
}

Map<String, String> _parse(List<String> a) {
  final m = <String, String>{};
  for (var i = 0; i + 1 < a.length; i += 2) {
    m[a[i].replaceFirst('--', '')] = a[i + 1];
  }
  return m;
}

void _usage() {
  stderr.writeln('Usage:\n  license_tool.dart keygen\n'
      '  license_tool.dart issue --machine XXXX-XXXX-XXXX-XXXX --to "Store Name" [--expires YYYY-MM-DD]');
  exit(64);
}
