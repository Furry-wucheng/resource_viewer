import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/data/models/enums.dart' show ResourceType;
import 'package:resource_viewer/data/repositories/resource_repository.dart';
import 'package:resource_viewer/data/repositories/source_repository.dart';
import 'package:resource_viewer/data/repositories/tag_repository.dart';
import 'package:resource_viewer/data/services/database_service.dart';
import 'package:resource_viewer/domain/core/paged_result.dart';
import 'package:resource_viewer/domain/core/result.dart';
import 'package:resource_viewer/domain/models/resource_query.dart';
import 'package:resource_viewer/domain/models/resource.dart' as domain;
import 'package:resource_viewer/domain/models/source.dart';

void main() {
  group('统一查询管线 ResourceRepository.queryResources', () {
    late AppDatabase db;
    late SourceRepository sources;
    late ResourceRepository resources;
    late TagRepository tags;

    /// 直接用 drift 插入以控制 createdAt 等字段
    Future<void> insertResourceRaw({
      required String id,
      required String sourceId,
      required String name,
      ResourceType type = ResourceType.folder,
      String relativePath = '',
      DateTime? createdAt,
    }) async {
      await db.createResource(
        ResourcesCompanion(
          id: Value(id),
          sourceId: Value(sourceId),
          name: Value(name),
          type: Value(type),
          relativePath: Value(relativePath),
          isAvailable: const Value(true),
          createdAt: createdAt != null ? Value(createdAt) : const Value.absent(),
        ),
      );
    }

    Future<void> seedStandard() async {
      await sources.createSource(
        id: 'source',
        name: '本地',
        type: SourceType.local,
        rootPath: '/tmp',
        isAvailable: true,
      );
      final now = DateTime(2024, 1, 1);
      for (var i = 0; i < 15; i++) {
        await insertResourceRaw(
          id: 'r_${i.toString().padLeft(3, '0')}',
          sourceId: 'source',
          name: 'resource_${i.toString().padLeft(3, '0')}',
          relativePath: 'path/r_$i',
          createdAt: now.add(Duration(seconds: i)),
        );
      }
    }

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      sources = SourceRepository(db);
      resources = ResourceRepository(db);
      tags = TagRepository(db);
    });

    tearDown(() => db.close());

    test('无筛选第一页返回 pageSize 条，hasMore 正确', () async {
      await seedStandard();

      final result = await resources.queryResources(
        ResourceQuery(pageSize: 10),
      );

      final page = (result as Ok<PagedResult<domain.Resource>>).value;
      expect(page.items.length, 10);
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, isNotNull);
    });

    test('最后一页 hasMore 为 false', () async {
      await seedStandard();

      final p1 = (await resources.queryResources(ResourceQuery(pageSize: 8)))
          as Ok<PagedResult<domain.Resource>>;
      expect(p1.value.hasMore, isTrue);

      final p2 = (await resources.queryResources(
        ResourceQuery(
          pageSize: 8,
          cursor: ResourceCursor.decode(p1.value.nextCursor!),
        ),
      )) as Ok<PagedResult<domain.Resource>>;
      expect(p2.value.items.length, 7);
      expect(p2.value.hasMore, isFalse);
      expect(p2.value.nextCursor, isNull);
    });

    test('空库返回空页', () async {
      await sources.createSource(
        id: 'source',
        name: '本地',
        type: SourceType.local,
        rootPath: '/tmp',
        isAvailable: true,
      );

      final result = await resources.queryResources(ResourceQuery());
      final page = (result as Ok<PagedResult<domain.Resource>>).value;
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });

    test('重复 createdAt 时不漏项不重复', () async {
      await sources.createSource(
        id: 'source',
        name: '本地',
        type: SourceType.local,
        rootPath: '/tmp',
        isAvailable: true,
      );
      final sameTime = DateTime(2024, 1, 1);
      for (final id in ['r_a', 'r_b', 'r_c', 'r_d', 'r_e']) {
        await insertResourceRaw(
          id: id,
          sourceId: 'source',
          name: id,
          relativePath: id,
          createdAt: sameTime,
        );
      }

      final p1 = (await resources.queryResources(ResourceQuery(pageSize: 3)))
          as Ok<PagedResult<domain.Resource>>;
      expect(p1.value.items.length, 3);
      expect(p1.value.hasMore, isTrue);

      final p2 = (await resources.queryResources(
        ResourceQuery(
          pageSize: 3,
          cursor: ResourceCursor.decode(p1.value.nextCursor!),
        ),
      )) as Ok<PagedResult<domain.Resource>>;
      expect(p2.value.items.length, 2);
      expect(p2.value.hasMore, isFalse);

      final allIds = [
        ...p1.value.items.map((r) => r.id),
        ...p2.value.items.map((r) => r.id),
      ];
      expect(allIds.toSet().length, 5);
    });

    test('禁用 Source 的资源不出现', () async {
      await sources.createSource(
        id: 'source_a',
        name: '可用源',
        type: SourceType.local,
        rootPath: '/a',
        isAvailable: true,
      );
      await sources.createSource(
        id: 'source_b',
        name: '禁用源',
        type: SourceType.local,
        rootPath: '/b',
        enabled: false,
        isAvailable: true,
      );
      await insertResourceRaw(id: 'r_a', sourceId: 'source_a', name: '可见', relativePath: 'a');
      await insertResourceRaw(id: 'r_b', sourceId: 'source_b', name: '不可见', relativePath: 'b');

      final result = await resources.queryResources(ResourceQuery());
      final page = (result as Ok<PagedResult<domain.Resource>>).value;
      expect(page.items.map((r) => r.id), ['r_a']);
    });

    test('不可达 Source 的资源不出现', () async {
      await sources.createSource(
        id: 'source_a',
        name: '可达',
        type: SourceType.local,
        rootPath: '/a',
        isAvailable: true,
      );
      await sources.createSource(
        id: 'source_b',
        name: '不可达',
        type: SourceType.local,
        rootPath: '/b',
        isAvailable: false,
      );
      await insertResourceRaw(id: 'r_a', sourceId: 'source_a', name: '可见', relativePath: 'a');
      await insertResourceRaw(id: 'r_b', sourceId: 'source_b', name: '隐藏', relativePath: 'b');

      final result = await resources.queryResources(ResourceQuery());
      final page = (result as Ok<PagedResult<domain.Resource>>).value;
      expect(page.items.map((r) => r.id), ['r_a']);
    });

    test('单标签筛选返回正确结果', () async {
      await sources.createSource(
        id: 'source',
        name: '本地',
        type: SourceType.local,
        rootPath: '/tmp',
        isAvailable: true,
      );
      await tags.createTag(id: 't1', name: '标签1', color: '#111111');
      for (final id in ['r_a', 'r_b', 'r_c']) {
        await insertResourceRaw(id: id, sourceId: 'source', name: id, relativePath: id);
      }
      await tags.addTagToResource('r_a', 't1');
      await tags.addTagToResource('r_c', 't1');

      final result = await resources.queryResources(
        ResourceQuery(tagIds: ['t1']),
      );
      final page = (result as Ok<PagedResult<domain.Resource>>).value;
      expect(page.items.map((r) => r.id).toSet(), {'r_a', 'r_c'});
    });

    test('多标签交集筛选返回正确结果', () async {
      await sources.createSource(
        id: 'source',
        name: '本地',
        type: SourceType.local,
        rootPath: '/tmp',
        isAvailable: true,
      );
      await tags.createTag(id: 't1', name: 'A', color: '#111111');
      await tags.createTag(id: 't2', name: 'B', color: '#222222');
      for (final id in ['r_a', 'r_b', 'r_c']) {
        await insertResourceRaw(id: id, sourceId: 'source', name: id, relativePath: id);
      }
      await tags.addTagToResource('r_a', 't1');
      await tags.addTagToResource('r_a', 't2');
      await tags.addTagToResource('r_b', 't1');
      await tags.addTagToResource('r_c', 't2');

      final result = await resources.queryResources(
        ResourceQuery(tagIds: ['t1', 't2']),
      );
      final page = (result as Ok<PagedResult<domain.Resource>>).value;
      expect(page.items.map((r) => r.id), ['r_a']);
    });

    test('搜索筛选 LIKE 匹配', () async {
      await sources.createSource(
        id: 'source',
        name: '本地',
        type: SourceType.local,
        rootPath: '/tmp',
        isAvailable: true,
      );
      await insertResourceRaw(id: 'r_a', sourceId: 'source', name: 'HelloWorld', relativePath: 'a');
      await insertResourceRaw(id: 'r_b', sourceId: 'source', name: 'hello_kitty', relativePath: 'b');
      await insertResourceRaw(id: 'r_c', sourceId: 'source', name: 'nothing', relativePath: 'c');

      final result = await resources.queryResources(
        ResourceQuery(searchQuery: 'hello'),
      );
      final page = (result as Ok<PagedResult<domain.Resource>>).value;
      final ids = page.items.map((r) => r.id).toSet();
      expect(ids, contains('r_a'));
      expect(ids, contains('r_b'));
      expect(ids, isNot(contains('r_c')));
    });

    test('搜索 + 标签组合筛选', () async {
      await sources.createSource(
        id: 'source',
        name: '本地',
        type: SourceType.local,
        rootPath: '/tmp',
        isAvailable: true,
      );
      await tags.createTag(id: 't1', name: '标签', color: '#111111');
      await insertResourceRaw(id: 'r_a', sourceId: 'source', name: 'Hello漫画', relativePath: 'a');
      await insertResourceRaw(id: 'r_b', sourceId: 'source', name: 'Hello画集', relativePath: 'b');
      await tags.addTagToResource('r_a', 't1');

      final result = await resources.queryResources(
        ResourceQuery(searchQuery: 'Hello', tagIds: ['t1']),
      );
      final page = (result as Ok<PagedResult<domain.Resource>>).value;
      expect(page.items.map((r) => r.id), ['r_a']);
    });

    test('收藏筛选返回正确结果', () async {
      await sources.createSource(
        id: 'source',
        name: '本地',
        type: SourceType.local,
        rootPath: '/tmp',
        isAvailable: true,
      );
      const favTagId = '00000000-0000-0000-0000-000000000001';
      await insertResourceRaw(id: 'r_a', sourceId: 'source', name: 'r_a', relativePath: 'a');
      await insertResourceRaw(id: 'r_b', sourceId: 'source', name: 'r_b', relativePath: 'b');
      await tags.addTagToResource('r_a', favTagId);

      final result = await resources.queryResources(
        ResourceQuery(favoriteOnly: true),
      );
      final page = (result as Ok<PagedResult<domain.Resource>>).value;
      expect(page.items.map((r) => r.id), ['r_a']);
    });

    test('计数查询与分页查询一致', () async {
      await sources.createSource(
        id: 'source',
        name: '本地',
        type: SourceType.local,
        rootPath: '/tmp',
        isAvailable: true,
      );
      await tags.createTag(id: 't1', name: 'A', color: '#111111');
      final now = DateTime(2024, 1, 1);
      for (var i = 0; i < 20; i++) {
        final id = 'r_$i';
        await insertResourceRaw(
          id: id,
          sourceId: 'source',
          name: id,
          relativePath: id,
          createdAt: now.add(Duration(seconds: i)),
        );
        if (i % 2 == 0) {
          await tags.addTagToResource(id, 't1');
        }
      }

      final count = await resources.countQueryResources(
        ResourceQuery(tagIds: ['t1']),
      );
      expect((count as Ok<int>).value, 10);

      var collected = 0;
      String? cursor;
      do {
        final result = await resources.queryResources(
          ResourceQuery(
            tagIds: ['t1'],
            pageSize: 3,
            cursor: ResourceCursor.decode(cursor),
          ),
        );
        final page = (result as Ok<PagedResult<domain.Resource>>).value;
        collected += page.items.length;
        cursor = page.nextCursor;
      } while (cursor != null);

      expect(collected, 10);
    });
  });
}
