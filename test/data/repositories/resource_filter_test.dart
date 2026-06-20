import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/data/repositories/resource_repository.dart';
import 'package:resource_viewer/data/repositories/source_repository.dart';
import 'package:resource_viewer/data/repositories/tag_repository.dart';
import 'package:resource_viewer/data/services/database_service.dart';
import 'package:resource_viewer/domain/core/result.dart';
import 'package:resource_viewer/domain/models/resource.dart' as domain;
import 'package:resource_viewer/domain/models/source.dart';

void main() {
  test('多标签筛选使用交集语义，计数与结果一致', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final sources = SourceRepository(db);
    final resources = ResourceRepository(db);
    final tags = TagRepository(db);

    await sources.createSource(
      id: 'source',
      name: '本地',
      type: SourceType.local,
      rootPath: '/tmp',
    );
    for (final id in ['both', 'only-a']) {
      await resources.createResource(
        id: id,
        sourceId: 'source',
        name: id,
        type: domain.ResourceType.folder,
        relativePath: id,
      );
    }
    await tags.createTag(id: 'a', name: 'A', color: '#111111');
    await tags.createTag(id: 'b', name: 'B', color: '#222222');
    await tags.addTagToResource('both', 'a');
    await tags.addTagToResource('both', 'b');
    await tags.addTagToResource('only-a', 'a');

    final result = await resources.filterByTags(['a', 'b', 'a']);
    final count = await resources.countFiltered(['a', 'b', 'a']);

    expect(result, isA<Ok<List<domain.Resource>>>());
    expect((result as Ok<List<domain.Resource>>).value.map((item) => item.id), [
      'both',
    ]);
    expect((count as Ok<int>).value, 1);
  });
}
