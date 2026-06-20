import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/data/repositories/resource_repository.dart';
import 'package:resource_viewer/data/repositories/source_repository.dart';
import 'package:resource_viewer/data/services/database_service.dart';
import 'package:resource_viewer/data/services/thumbnail_cache_service.dart';
import 'package:resource_viewer/domain/models/resource.dart';
import 'package:resource_viewer/domain/models/source.dart';

void main() {
  test('删除 Source 同时删除其资源缩略图', () async {
    final temp = await Directory.systemTemp.createTemp('source_delete_test_');
    addTearDown(() => temp.delete(recursive: true));
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final cache = ThumbnailCacheService(cacheDirectory: temp.path);
    final sources = SourceRepository(db, thumbnailCacheService: cache);
    final resources = ResourceRepository(db);

    await sources.createSource(
      id: 'source',
      name: '本地',
      type: SourceType.local,
      rootPath: temp.path,
    );
    await resources.createResource(
      id: 'resource',
      sourceId: 'source',
      name: '资源',
      type: ResourceType.folder,
      relativePath: 'resource',
    );
    await cache.put('resource', List.filled(32, 1));

    await sources.deleteSource('source');

    expect(await cache.get('resource'), isNull);
  });
}
