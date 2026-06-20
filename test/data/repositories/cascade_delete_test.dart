import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:resource_viewer/data/services/database_service.dart';
import 'package:resource_viewer/data/repositories/source_repository.dart';
import 'package:resource_viewer/data/repositories/resource_repository.dart';
import 'package:resource_viewer/data/repositories/tag_repository.dart';
import 'package:resource_viewer/domain/core/result.dart';
import 'package:resource_viewer/domain/models/source.dart' as domain_source;
import 'package:resource_viewer/domain/models/resource.dart' as domain_resource;
import 'package:resource_viewer/domain/models/tag.dart' as domain_tag;

void main() {
  late AppDatabase db;
  late SourceRepository sourceRepository;
  late ResourceRepository resourceRepository;
  late TagRepository tagRepository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sourceRepository = SourceRepository(db);
    resourceRepository = ResourceRepository(db);
    tagRepository = TagRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('级联删除测试', () {
    test('删除 Source → 其下 Resources 和 ResourceTags 被级联删除', () async {
      // 1. 创建数据源
      final sourceResult = await sourceRepository.createSource(
        id: 'source-1',
        name: '测试数据源',
        type: domain_source.SourceType.local,
        rootPath: '/test/path',
      );
      expect(sourceResult, isA<Ok>());

      // 2. 创建资源
      final resourceResult = await resourceRepository.createResource(
        id: 'resource-1',
        sourceId: 'source-1',
        name: '测试资源',
        type: domain_resource.ResourceType.folder,
        relativePath: '/test/resource',
      );
      expect(resourceResult, isA<Ok>());

      // 3. 创建标签（除了内置标签外）
      final tagResult = await tagRepository.createTag(
        id: 'tag-1',
        name: '测试标签',
        color: '#FF0000',
      );
      expect(tagResult, isA<Ok>());

      // 4. 为资源添加标签
      final addTagResult = await tagRepository.addTagToResource(
        'resource-1',
        'tag-1',
      );
      expect(addTagResult, isA<Ok>());

      // 5. 验证资源存在
      final resourceCheck = await resourceRepository.getResourceById(
        'resource-1',
      );
      expect(resourceCheck, isA<Ok>());
      expect((resourceCheck as Ok).value, isNotNull);

      // 6. 验证资源标签存在
      final tagsForResource = await tagRepository.getTagsForResource(
        'resource-1',
      );
      expect(tagsForResource, isA<Ok>());
      final tags = (tagsForResource as Ok).value as List<domain_tag.Tag>;
      expect(tags.length, 1);
      expect(tags.first.id, 'tag-1');

      // 7. 删除数据源
      final deleteResult = await sourceRepository.deleteSource('source-1');
      expect(deleteResult, isA<Ok>());

      // 8. 验证数据源已被删除
      final sourceCheck = await sourceRepository.getSourceById('source-1');
      expect(sourceCheck, isA<Ok>());
      expect((sourceCheck as Ok).value, isNull);

      // 9. 验证资源已被级联删除
      final resourceCheckAfter = await resourceRepository.getResourceById(
        'resource-1',
      );
      expect(resourceCheckAfter, isA<Ok>());
      expect((resourceCheckAfter as Ok).value, isNull);

      // 10. 验证资源标签已被级联删除
      // 注意：由于资源已被删除，我们无法直接查询其标签
      // 但我们可以通过查询标签下的资源来验证
      final resourcesForTag = await tagRepository.getResourceIdsForTag('tag-1');
      expect(resourcesForTag, isA<Ok>());
      final resourceIds = (resourcesForTag as Ok).value as List<String>;
      expect(resourceIds.length, 0);

      // 11. 验证标签本身仍然存在（标签不随数据源删除）
      final tagCheck = await tagRepository.getTagById('tag-1');
      expect(tagCheck, isA<Ok>());
      expect((tagCheck as Ok).value, isNotNull);
    });

    test('删除 Resource → 其 ResourceTags 被级联删除', () async {
      // 1. 创建数据源
      await sourceRepository.createSource(
        id: 'source-1',
        name: '测试数据源',
        type: domain_source.SourceType.local,
        rootPath: '/test/path',
      );

      // 2. 创建资源
      await resourceRepository.createResource(
        id: 'resource-1',
        sourceId: 'source-1',
        name: '测试资源',
        type: domain_resource.ResourceType.folder,
        relativePath: '/test/resource',
      );

      // 3. 创建标签
      await tagRepository.createTag(
        id: 'tag-1',
        name: '测试标签',
        color: '#FF0000',
      );

      // 4. 为资源添加标签
      await tagRepository.addTagToResource('resource-1', 'tag-1');

      // 5. 验证资源标签存在
      final tagsBefore = await tagRepository.getTagsForResource('resource-1');
      expect(tagsBefore, isA<Ok>());
      expect((tagsBefore as Ok).value as List, hasLength(1));

      // 6. 删除资源
      final deleteResult = await resourceRepository.deleteResource(
        'resource-1',
      );
      expect(deleteResult, isA<Ok>());

      // 7. 验证资源标签已被级联删除
      final resourcesForTag = await tagRepository.getResourceIdsForTag('tag-1');
      expect(resourcesForTag, isA<Ok>());
      expect((resourcesForTag as Ok).value as List, hasLength(0));

      // 8. 验证标签本身仍然存在
      final tagCheck = await tagRepository.getTagById('tag-1');
      expect(tagCheck, isA<Ok>());
      expect((tagCheck as Ok).value, isNotNull);
    });

    test('删除 Tag → 其 ResourceTags 被级联删除', () async {
      // 1. 创建数据源
      await sourceRepository.createSource(
        id: 'source-1',
        name: '测试数据源',
        type: domain_source.SourceType.local,
        rootPath: '/test/path',
      );

      // 2. 创建资源
      await resourceRepository.createResource(
        id: 'resource-1',
        sourceId: 'source-1',
        name: '测试资源',
        type: domain_resource.ResourceType.folder,
        relativePath: '/test/resource',
      );

      // 3. 创建标签
      await tagRepository.createTag(
        id: 'tag-1',
        name: '测试标签',
        color: '#FF0000',
      );

      // 4. 为资源添加标签
      await tagRepository.addTagToResource('resource-1', 'tag-1');

      // 5. 验证资源有标签
      final tagsBefore = await tagRepository.getTagsForResource('resource-1');
      expect(tagsBefore, isA<Ok>());
      expect((tagsBefore as Ok).value as List, hasLength(1));

      // 6. 删除标签
      final deleteResult = await tagRepository.deleteTag('tag-1');
      expect(deleteResult, isA<Ok>());

      // 7. 验证资源标签已被级联删除
      final tagsAfter = await tagRepository.getTagsForResource('resource-1');
      expect(tagsAfter, isA<Ok>());
      expect((tagsAfter as Ok).value as List, hasLength(0));

      // 8. 验证资源本身仍然存在
      final resourceCheck = await resourceRepository.getResourceById(
        'resource-1',
      );
      expect(resourceCheck, isA<Ok>());
      expect((resourceCheck as Ok).value, isNotNull);
    });
  });
}
