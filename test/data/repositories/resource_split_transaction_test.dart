import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/data/repositories/resource_repository.dart';
import 'package:resource_viewer/data/repositories/source_repository.dart';
import 'package:resource_viewer/domain/core/result.dart';
import 'package:resource_viewer/domain/models/resource.dart';
import 'package:resource_viewer/domain/models/source.dart';

import '../../helpers/test_database.dart';

void main() {
  test(
    'split creation rolls back all children and original deletion on failure',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final sources = SourceRepository(database);
      final resources = ResourceRepository(database);
      await sources.createSource(
        id: 'source',
        name: 'Source',
        type: SourceType.local,
        rootPath: 'root',
      );
      await resources.createResource(
        id: 'original',
        sourceId: 'source',
        name: 'Original',
        type: ResourceType.folder,
        relativePath: 'book',
      );

      final now = DateTime.now();
      Resource child(String id) => Resource(
        id: id,
        sourceId: 'source',
        name: id,
        type: ResourceType.folder,
        relativePath: 'book/same-path',
        createdAt: now,
        updatedAt: now,
      );

      final result = await resources.commitResourceSplit(
        children: [child('child-1'), child('child-2')],
        originalId: 'original',
        deleteOriginal: true,
      );

      expect(result, isA<Err>());
      expect((await resources.getResourceById('child-1') as Ok).value, isNull);
      expect((await resources.getResourceById('child-2') as Ok).value, isNull);
      expect(
        (await resources.getResourceById('original') as Ok).value,
        isNotNull,
      );
    },
  );
}
