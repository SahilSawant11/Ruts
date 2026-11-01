import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/auth/app_user.dart';
import 'package:pos_app/core/auth/auth_repository.dart';
import 'package:pos_app/core/auth/password_hasher.dart';
import 'package:pos_app/core/licensing/license_codec.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/core/local/backup_service.dart';
import 'package:pos_app/core/local/db_paths.dart';
import 'package:pos_app/core/network/api_exception.dart';

import 'support/test_env.dart';

void main() {
  late TestEnv env;
  setUp(() async => env = await TestEnv.create());
  tearDown(() async => env.dispose());

  group('Bill numbers', () {
    test('financial year code follows Indian FY (Apr–Mar)', () {
      expect(AppDatabase.financialYearCode(DateTime(2026, 11, 1)), '2627');
      expect(AppDatabase.financialYearCode(DateTime(2027, 3, 31)), '2627');
      expect(AppDatabase.financialYearCode(DateTime(2027, 4, 1)), '2728');
    });

    test('sequential, previewed correctly, and not burned by a failed sale', () async {
      await env.addMaterial('A', stock: 5);
      expect(await env.db.peekNextSalesBillNo(), 'CS-${AppDatabase.financialYearCode(DateTime.now())}-000001');

      final first = await env.sales.createSale(TestEnv.sale({'A': 2}));
      expect(first.billNo, endsWith('-000001'));

      // Insufficient stock → whole transaction rolls back, number not used.
      await expectLater(env.sales.createSale(TestEnv.sale({'A': 50})), throwsA(isA<ApiException>()));

      final second = await env.sales.createSale(TestEnv.sale({'A': 1}));
      expect(second.billNo, endsWith('-000002'));
      expect(await env.stockOf('A'), 2);
    });
  });

  group('Sale atomicity', () {
    test('bill, lines, stock and sync job are written together with device id', () async {
      await env.addMaterial('A', stock: 10);
      final result = await env.sales.createSale(TestEnv.sale({'A': 3}));

      final bill = await (env.db.select(env.db.cachedSalesBills)..where((t) => t.id.equals(result.id))).getSingle();
      expect(bill.deviceId, await env.db.deviceId());
      expect(result.id, startsWith('local-sale-'));

      final queue = await env.db.select(env.db.syncQueueItems).get();
      expect(queue, hasLength(1));
      expect(queue.single.entityId, result.id);
      expect(queue.single.payload, contains(result.billNo));
    });

    test('failed sale leaves no bill and no sync job', () async {
      await env.addMaterial('A', stock: 1);
      await expectLater(env.sales.createSale(TestEnv.sale({'A': 2})), throwsA(isA<ApiException>()));
      expect(await env.db.select(env.db.cachedSalesBills).get(), isEmpty);
      expect(await env.db.select(env.db.syncQueueItems).get(), isEmpty);
      expect(await env.stockOf('A'), 1);
    });
  });

  group('Starter data', () {
    test('production seeding adds lookups only, and never re-seeds', () async {
      await env.db.ensureStarterData(includeDemoData: false);
      expect(await env.db.select(env.db.cachedSalesBills).get(), isEmpty);
      expect(await env.db.select(env.db.cachedMaterials).get(), isEmpty);
      expect(await env.db.select(env.db.cachedLicenseHolders).get(), isNotEmpty);

      await env.db.delete(env.db.cachedLicenseHolders).go();
      await env.db.ensureStarterData(includeDemoData: true);
      expect(await env.db.select(env.db.cachedLicenseHolders).get(), isEmpty,
          reason: 'second call must be a no-op');
      expect(await env.db.select(env.db.cachedSalesBills).get(), isEmpty);
    });

    test('existing store data is never overwritten by demo data', () async {
      await env.addMaterial('REAL', stock: 3);
      await env.db.ensureStarterData(includeDemoData: true);
      expect(await env.db.select(env.db.cachedSalesBills).get(), isEmpty);
      expect((await env.db.select(env.db.cachedMaterials).get()).map((m) => m.id), ['REAL']);
    });
  });

  group('Auth', () {
    late AuthRepository auth;
    setUp(() async {
      auth = AuthRepository(env.db);
      await auth.ensureDefaultUsers();
    });

    test('passwords are hashed, never stored in plain text', () async {
      final rows = await env.db.select(env.db.appUsers).get();
      expect(rows, hasLength(3));
      for (final r in rows) {
        expect(r.passwordHash, startsWith(r'pbkdf2-sha256$'));
        expect(r.passwordHash, isNot(contains('123')));
        expect(r.mustChangePassword, isTrue);
      }
    });

    test('sign in, wrong password, lockout', () async {
      final user = await auth.signIn(username: ' Cashier ', password: 'cash123');
      expect(user.role, UserRole.cashier);
      expect(user.canOpen('/sales'), isTrue);
      expect(user.canOpen('/purchase'), isFalse);

      for (var i = 0; i < 5; i++) {
        await expectLater(auth.signIn(username: 'owner', password: 'nope'), throwsA(isA<ApiException>()));
      }
      // Locked even with the right password.
      await expectLater(
        auth.signIn(username: 'owner', password: 'owner123'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('Too many'))),
      );
    });

    test('session restores role from the database, not the file', () async {
      final owner = await auth.signIn(username: 'owner', password: 'owner123');
      expect((await auth.restoreSession())!.role, UserRole.owner);

      await (env.db.update(env.db.appUsers)..where((t) => t.id.equals(owner.id)))
          .write(const AppUsersCompanion(role: Value('cashier')));
      expect((await auth.restoreSession())!.role, UserRole.cashier);

      await (env.db.update(env.db.appUsers)..where((t) => t.id.equals(owner.id)))
          .write(const AppUsersCompanion(isActive: Value(false)));
      expect(await auth.restoreSession(), isNull);
    });

    test('change password and owner user management', () async {
      final owner = await auth.signIn(username: 'owner', password: 'owner123');
      await expectLater(
        auth.changePassword(userId: owner.id, currentPassword: 'wrong', newPassword: 'abcdef1'),
        throwsA(isA<ApiException>()),
      );
      await auth.changePassword(userId: owner.id, currentPassword: 'owner123', newPassword: 'Str0ngPass');
      expect((await auth.signIn(username: 'owner', password: 'Str0ngPass')).mustChangePassword, isFalse);

      await auth.createUser(username: 'ravi', displayName: 'Ravi', role: UserRole.cashier, password: 'ravi-pass');
      await expectLater(
        auth.createUser(username: 'ravi', displayName: 'X', role: UserRole.cashier, password: 'whatever'),
        throwsA(isA<ApiException>()),
      );
      await expectLater(auth.deactivateUser(owner.id, actingUserId: owner.id), throwsA(isA<ApiException>()));
    });

    test('hash format verifies across iteration counts', () async {
      final h = await PasswordHasher.hash('secret', iterations: 2000);
      expect(await PasswordHasher.verify('secret', h), isTrue);
      expect(await PasswordHasher.verify('Secret', h), isFalse);
      expect(await PasswordHasher.verify('secret', 'garbage'), isFalse);
    });
  });

  group('License codec', () {
    late SimpleKeyPair kp;
    late String pub;
    setUp(() async {
      kp = await Ed25519().newKeyPair();
      pub = _b64((await kp.extractPublicKey()).bytes);
    });

    LicenseData lic({String machine = 'AAAA-BBBB-CCCC-DDDD', DateTime? exp}) => LicenseData(
          licenseId: 'L1',
          licensedTo: 'Test Wines',
          machineId: machine,
          issuedAt: DateTime(2026, 11, 1),
          expiresAt: exp,
        );

    test('valid signature round-trips', () async {
      final key = await LicenseCodec.sign(lic(exp: DateTime(2027, 11, 30)), kp);
      final data = await LicenseCodec.verify(key, pub);
      expect(data!.licensedTo, 'Test Wines');
      expect(data.expiresAt, DateTime(2027, 11, 30));
      // Whitespace/newlines from copy-paste are tolerated.
      expect(await LicenseCodec.verify(' ${key.substring(0, 20)}\n${key.substring(20)} ', pub), isNotNull);
    });

    test('tampered payload or foreign key is rejected', () async {
      final key = await LicenseCodec.sign(lic(), kp);
      final parts = key.split('.');
      final forged = await LicenseCodec.sign(lic(machine: 'EEEE-FFFF-0000-1111'), await Ed25519().newKeyPair());
      expect(await LicenseCodec.verify('${parts[0]}.${forged.split('.')[1]}.${parts[2]}', pub), isNull);
      expect(await LicenseCodec.verify(forged, pub), isNull);
      expect(await LicenseCodec.verify('nonsense', pub), isNull);
    });
  });

  group('Backup & restore', () {
    test('backup is valid, quote-safe, and restore swaps data on next open', () async {
      await env.addMaterial('A', stock: 7);
      final service = BackupService(env.db);

      // Folder name with an apostrophe used to break VACUUM INTO.
      final odd = Directory(DbPaths.join(env.root.path, "Owner's Backups"));
      final backup = await service.backupNow(targetFolder: odd.path);
      expect(BackupService.validateBackup(backup), isNull);

      // Change data after the backup.
      await env.sales.createSale(TestEnv.sale({'A': 7}));
      expect(await env.stockOf('A'), 0);

      await service.stageRestore(backup);
      expect(await service.hasPendingRestore(), isTrue);
      await env.db.close();

      // Next launch: pending restore is applied before the DB opens.
      final path = await DbPaths.prepareDatabaseFile();
      final reopened = AppDatabase(NativeDatabase(File(path)));
      final stock = await (reopened.select(reopened.cachedInventoryStocks)..where((t) => t.materialId.equals('A'))).getSingle();
      expect(stock.qtyOnHand, 7);
      expect(await reopened.select(reopened.cachedSalesBills).get(), isEmpty);
      await reopened.close();

      final preRestore = (await DbPaths.backupsDir()).listSync().where((f) => f.path.contains('pre_restore'));
      expect(preRestore, isNotEmpty, reason: 'previous data kept as a safety copy');
      env = await _reopen(env);
    });

    test('rejects files that are not Caskly databases', () async {
      final junk = File(DbPaths.join(env.root.path, 'junk.sqlite'))..writeAsStringSync('hello');
      expect(BackupService.validateBackup(junk), isNotNull);
      expect(() => BackupService(env.db).stageRestore(junk), throwsA(isA<BackupException>()));
    });

    test('daily auto backup runs once per day and prunes old ones', () async {
      final service = BackupService(env.db);
      final t0 = DateTime.utc(2026, 11, 1, 9);
      expect(await service.autoBackupIfDue(now: t0), isNotNull);
      expect(await service.autoBackupIfDue(now: t0.add(const Duration(hours: 3))), isNull);
      for (var d = 1; d <= BackupService.keepAutoBackups + 3; d++) {
        await service.autoBackupIfDue(now: t0.add(Duration(days: d)));
      }
      final autos = (await service.listBackups()).where((b) => b.isAuto);
      expect(autos.length, BackupService.keepAutoBackups);
    });
  });
}

/// Replaces a TestEnv whose DB was closed mid-test so tearDown still works.
Future<TestEnv> _reopen(TestEnv old) async {
  final fresh = await TestEnv.create(fileBacked: false);
  await old.root.delete(recursive: true).catchError((_) => old.root);
  return fresh;
}

String _b64(List<int> bytes) => base64Encode(bytes);
