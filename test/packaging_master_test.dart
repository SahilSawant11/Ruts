import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/core/network/api_exception.dart';
import 'package:pos_app/features/masters/data/local_masters_repository.dart';
import 'package:pos_app/features/masters/data/masters_api_repository.dart';
import 'package:pos_app/features/masters/data/models/packaging_dto.dart';
import 'package:pos_app/features/masters/data/models/save_packaging_request.dart';
import 'package:pos_app/features/masters/presentation/packaging_browser_controller.dart';

void main() {
  group('Packaging Master Tests', () {
    late AppDatabase db;
    late LocalMastersRepository repo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db.ensureStarterData();
      repo = LocalMastersRepository(db, MastersApiRepository(http.Client()));
    });

    tearDown(() async {
      await db.close();
    });

    test('getPackings returns pre-populated starter packings based on inventory', () async {
      final packings = await repo.getPackings();
      expect(packings, isNotEmpty);
      final names = packings.map((p) => p.name).toList();
      expect(names, contains('750 ML'));
      expect(names, contains('650 ML'));
      expect(names, contains('330 ML'));
      expect(names, contains('300 ML'));
    });

    test('createPacking adds a new packaging entity', () async {
      const request = SavePackagingRequest(
        name: '1000 ML',
        description: '1 Litre bottle',
      );
      final created = await repo.createPacking(request);
      expect(created.name, '1000 ML');
      expect(created.description, '1 Litre bottle');

      final packings = await repo.getPackings();
      expect(packings.any((p) => p.name == '1000 ML'), isTrue);
    });

    test('createPacking throws ApiException on empty name or duplicate', () async {
      expect(
        () => repo.createPacking(const SavePackagingRequest(name: '  ')),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('required'))),
      );

      expect(
        () => repo.createPacking(const SavePackagingRequest(name: '750 ML')),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('already exists'))),
      );
    });

    test('updatePacking updates packaging name and cascades to materials', () async {
      // First verify there are materials with '750 ML'
      final materialsBefore = await (db.select(db.cachedMaterials)..where((t) => t.packing.equals('750 ML'))).get();
      expect(materialsBefore, isNotEmpty);

      const request = SavePackagingRequest(
        name: '750 ML (BOTTLE)',
        description: 'Standard 750ml bottle',
      );
      final updated = await repo.updatePacking('750 ML', request);
      expect(updated.name, '750 ML (BOTTLE)');

      // Verify cachedPackings updated
      final packings = await repo.getPackings();
      expect(packings.any((p) => p.name == '750 ML (BOTTLE)'), isTrue);
      expect(packings.any((p) => p.name == '750 ML'), isFalse);

      // Verify cascading update to materials
      final oldMaterials = await (db.select(db.cachedMaterials)..where((t) => t.packing.equals('750 ML'))).get();
      expect(oldMaterials, isEmpty);
      final newMaterials = await (db.select(db.cachedMaterials)..where((t) => t.packing.equals('750 ML (BOTTLE)'))).get();
      expect(newMaterials.length, materialsBefore.length);
    });

    test('PackagingBrowserController handles navigation and selection', () {
      final controller = PackagingBrowserController();
      const items = [
        PackagingDto(name: '180 ML', description: 'Quarter'),
        PackagingDto(name: '375 ML', description: 'Half'),
        PackagingDto(name: '750 ML', description: 'Full'),
      ];

      controller.syncList(items);
      expect(controller.state.packings.length, 3);
      expect(controller.state.index, -1);

      controller.selectByName('375 ML');
      expect(controller.state.index, 1);
      expect(controller.state.current?.name, '375 ML');
      expect(controller.state.hasPrev, isTrue);
      expect(controller.state.hasNext, isTrue);

      controller.next();
      expect(controller.state.index, 2);
      expect(controller.state.current?.name, '750 ML');
      expect(controller.state.hasNext, isFalse);

      controller.prev();
      expect(controller.state.index, 1);

      controller.startNew();
      expect(controller.state.isNew, isTrue);
      expect(controller.state.isEditing, isTrue);
    });
  });
}
