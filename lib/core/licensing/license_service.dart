import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/db_paths.dart';
import '../logging/app_logger.dart';
import 'license_codec.dart';
import 'license_keys.dart';
import 'machine_id.dart';

enum LicenseState { valid, missing, invalid, wrongMachine, expired, clockTampered, notEnforced }

class LicenseStatus {
  const LicenseStatus(this.state, {required this.machineId, this.data, this.message});

  final LicenseState state;
  final String machineId;
  final LicenseData? data;
  final String? message;

  bool get allowsUse => state == LicenseState.valid || state == LicenseState.notEnforced;

  int? get daysLeft => data?.expiresAt?.difference(DateTime.now()).inDays;
}

/// Checks and stores the license key. Licensing is enforced in release
/// builds; debug builds skip it unless built with
/// --dart-define=CASKLY_ENFORCE_LICENSE=true.
class LicenseService {
  LicenseService({String publicKey = casklyLicensePublicKey, bool? enforce})
      : _publicKey = publicKey,
        _enforce = enforce ?? (kReleaseMode || const bool.fromEnvironment('CASKLY_ENFORCE_LICENSE'));

  final String _publicKey;
  final bool _enforce;

  /// Clock may run up to this far behind the last time we saw it before we
  /// treat it as someone winding the clock back to dodge an expiry.
  static const _clockTolerance = Duration(days: 2);

  Future<File> _keyFile() async => File(DbPaths.join((await DbPaths.root()).path, 'license.key'));
  Future<File> _seenFile() async => File(DbPaths.join((await DbPaths.root()).path, 'license.seen'));

  Future<LicenseStatus> check() async {
    final machineId = await MachineId.get();
    if (!_enforce) return LicenseStatus(LicenseState.notEnforced, machineId: machineId);

    final file = await _keyFile();
    if (!await file.exists()) return LicenseStatus(LicenseState.missing, machineId: machineId);
    return _evaluate(await file.readAsString(), machineId, recordClock: true);
  }

  /// Validates [key] for this machine and saves it if valid.
  Future<LicenseStatus> activate(String key) async {
    final machineId = await MachineId.get();
    final status = await _evaluate(key, machineId, recordClock: true);
    if (status.state == LicenseState.valid) {
      await (await _keyFile()).writeAsString(key.trim());
      AppLogger.info('License', 'Activated ${status.data!.licenseId} for ${status.data!.licensedTo}');
    } else {
      AppLogger.warn('License', 'Activation rejected: ${status.state.name}');
    }
    return status;
  }

  Future<LicenseStatus> _evaluate(String key, String machineId, {required bool recordClock}) async {
    final data = await LicenseCodec.verify(key, _publicKey);
    if (data == null) {
      return LicenseStatus(LicenseState.invalid,
          machineId: machineId, message: 'This license key is not valid. Check it was copied completely.');
    }
    if (LicenseCodec.normaliseMachineId(data.machineId) != machineId) {
      return LicenseStatus(LicenseState.wrongMachine,
          machineId: machineId,
          data: data,
          message: 'This license belongs to another computer (${data.machineId}).');
    }

    final now = DateTime.now();
    if (data.expiresAt != null) {
      final seenFile = await _seenFile();
      final lastSeen = await seenFile.exists() ? DateTime.tryParse(await seenFile.readAsString()) : null;
      if (lastSeen != null && now.isBefore(lastSeen.subtract(_clockTolerance))) {
        return LicenseStatus(LicenseState.clockTampered,
            machineId: machineId, data: data, message: 'The computer clock appears to be set in the past.');
      }
      if (recordClock && (lastSeen == null || now.isAfter(lastSeen))) {
        await seenFile.writeAsString(now.toIso8601String());
      }
      final endOfDay = DateTime(data.expiresAt!.year, data.expiresAt!.month, data.expiresAt!.day, 23, 59, 59);
      if (now.isAfter(endOfDay)) {
        return LicenseStatus(LicenseState.expired, machineId: machineId, data: data, message: 'This license has expired.');
      }
    }
    return LicenseStatus(LicenseState.valid, machineId: machineId, data: data);
  }
}

final licenseServiceProvider = Provider<LicenseService>((ref) => LicenseService());

final licenseStatusProvider = FutureProvider<LicenseStatus>((ref) {
  return ref.watch(licenseServiceProvider).check();
});
