import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:resource_viewer/data/services/database_service.dart';
import 'package:resource_viewer/data/models/enums.dart';
import 'package:resource_viewer/data/repositories/tag_repository.dart';
import 'package:resource_viewer/domain/core/result.dart';
import 'package:resource_viewer/domain/models/tag.dart' as domain;

void main() {
  late AppDatabase db;
  late TagRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = TagRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TagRepository', () {
    test('标签播种测试 - 数据库初始化后包含内置标签"收藏"', () async {
      final result = await repository.getAllTags();

      expect(result, isA<Ok>());
      final tags = (result as Ok).value as List<domain.Tag>;

      expect(tags.length, 1);
      expect(tags.first.name, '收藏');
      expect(tags.first.color, '#FFC107');
      expect(tags.first.isBuiltIn, true);
      expect(tags.first.id, '00000000-0000-0000-0000-000000000001');
    });

    test('getAllTags - 内置标签在前，自定义按创建时间倒序', () async {
      // 创建多个自定义标签
      await repository.createTag(id: 'tag-1', name: '标签1', color: '#FF0000');
      await repository.createTag(id: 'tag-2', name: '标签2', color: '#00FF00');
      await repository.createTag(id: 'tag-3', name: '标签3', color: '#0000FF');

      final result = await repository.getAllTags();
      expect(result, isA<Ok>());
      final tags = (result as Ok).value as List<domain.Tag>;

      // 第一个是内置标签
      expect(tags.first.isBuiltIn, true);
      expect(tags.first.name, '收藏');

      // 自定义标签按创建时间倒序（最新创建的在前）
      final customTags = tags.where((t) => !t.isBuiltIn).toList();
      expect(customTags.length, 3);
      // 验证排序：每个标签的 createdAt 应该 >= 下一个标签的 createdAt
      for (int i = 0; i < customTags.length - 1; i++) {
        expect(
          customTags[i].createdAt.isAfter(customTags[i + 1].createdAt) ||
              customTags[i].createdAt.isAtSameMomentAs(
                customTags[i + 1].createdAt,
              ),
          true,
          reason:
              '${customTags[i].name} should be after or same as ${customTags[i + 1].name}',
        );
      }
    });

    test('创建标签 - 成功创建自定义标签', () async {
      final result = await repository.createTag(
        id: 'test-tag-1',
        name: '测试标签',
        color: '#FF0000',
      );

      expect(result, isA<Ok>());
      final tag = (result as Ok).value as domain.Tag;

      expect(tag.id, 'test-tag-1');
      expect(tag.name, '测试标签');
      expect(tag.color, '#FF0000');
      expect(tag.isBuiltIn, false);
    });

    test('创建标签 - 标签名重复时返回 ValidationError', () async {
      await repository.createTag(
        id: 'test-tag-1',
        name: '测试标签',
        color: '#FF0000',
      );

      final result = await repository.createTag(
        id: 'test-tag-2',
        name: '测试标签',
        color: '#00FF00',
      );

      expect(result, isA<Err>());
      final error = (result as Err).error;
      expect(error, isA<ValidationError>());
      expect(error.message, contains('已存在'));
    });

    test('创建标签 - 标签名为空时返回 ValidationError', () async {
      final result = await repository.createTag(
        id: 'test-tag-1',
        name: '',
        color: '#FF0000',
      );

      expect(result, isA<Err>());
      final error = (result as Err).error;
      expect(error, isA<ValidationError>());
      expect(error.message, contains('不能为空'));
    });

    test('创建标签 - 使用内置标签名"收藏"时返回 ValidationError', () async {
      final result = await repository.createTag(
        id: 'test-tag-1',
        name: '收藏',
        color: '#FF0000',
      );

      expect(result, isA<Err>());
      final error = (result as Err).error;
      expect(error, isA<ValidationError>());
      expect(error.message, contains('内置标签'));
    });

    test('创建标签 - 标签名超过20字符返回 ValidationError', () async {
      final result = await repository.createTag(
        id: 'test-tag-1',
        name: '123456789012345678901',
        color: '#FF0000',
      );

      expect(result, isA<Err>());
      final error = (result as Err).error;
      expect(error, isA<ValidationError>());
      expect(error.message, contains('不能超过'));
    });

    test('renameTag - 成功重命名自定义标签', () async {
      await repository.createTag(
        id: 'test-tag-1',
        name: '原名称',
        color: '#FF0000',
      );

      final result = await repository.renameTag('test-tag-1', '新名称');
      if (result is Err) {
        fail('renameTag failed: ${(result as Err).error.message}');
      }
      expect(result, isA<Ok>());
      final tag = (result as Ok).value as domain.Tag;
      expect(tag.name, '新名称');
      expect(tag.color, '#FF0000'); // 颜色不变
    });

    test('renameTag - 内置标签不可重命名', () async {
      final tagsResult = await repository.getAllTags();
      final tags = (tagsResult as Ok).value as List<domain.Tag>;
      final builtInTag = tags.first;

      final result = await repository.renameTag(builtInTag.id, '新名称');
      expect(result, isA<Err>());
      final error = (result as Err).error;
      expect(error, isA<ValidationError>());
      expect(error.message, contains('内置标签不可重命名'));
    });

    test('renameTag - 重命名为已存在的名称返回 ValidationError', () async {
      await repository.createTag(id: 'tag-1', name: '标签1', color: '#FF0000');
      await repository.createTag(id: 'tag-2', name: '标签2', color: '#00FF00');

      final result = await repository.renameTag('tag-1', '标签2');
      expect(result, isA<Err>());
      final error = (result as Err).error;
      expect(error, isA<ValidationError>());
      expect(error.message, contains('已存在'));
    });

    test('renameTag - 重命名为自身名称成功', () async {
      await repository.createTag(
        id: 'test-tag-1',
        name: '测试标签',
        color: '#FF0000',
      );

      final result = await repository.renameTag('test-tag-1', '测试标签');
      expect(result, isA<Ok>());
    });

    test('updateColor - 成功修改标签颜色', () async {
      await repository.createTag(
        id: 'test-tag-1',
        name: '测试标签',
        color: '#FF0000',
      );

      final result = await repository.updateColor('test-tag-1', '#00FF00');
      expect(result, isA<Ok>());
      final tag = (result as Ok).value as domain.Tag;
      expect(tag.color, '#00FF00');
      expect(tag.name, '测试标签'); // 名称不变
    });

    test('updateColor - 颜色格式不正确返回 ValidationError', () async {
      await repository.createTag(
        id: 'test-tag-1',
        name: '测试标签',
        color: '#FF0000',
      );

      final result = await repository.updateColor('test-tag-1', 'red');
      expect(result, isA<Err>());
      final error = (result as Err).error;
      expect(error, isA<ValidationError>());
      expect(error.message, contains('颜色格式'));
    });

    test('updateColor - 内置标签颜色不可修改', () async {
      final result = await repository.updateColor(
        '00000000-0000-0000-0000-000000000001',
        '#000000',
      );

      expect(result, isA<Err>());
      expect((result as Err).error, isA<ValidationError>());
    });

    test('deleteTag - 内置标签不可删除', () async {
      final tagsResult = await repository.getAllTags();
      final tags = (tagsResult as Ok).value as List<domain.Tag>;
      final builtInTag = tags.first;

      final result = await repository.deleteTag(builtInTag.id);

      expect(result, isA<Err>());
      final error = (result as Err).error;
      expect(error, isA<ValidationError>());
      expect(error.message, contains('内置标签不可删除'));

      final checkResult = await repository.getTagById(builtInTag.id);
      expect(checkResult, isA<Ok>());
      expect((checkResult as Ok).value, isNotNull);
    });

    test('deleteTag - 成功删除自定义标签', () async {
      await repository.createTag(
        id: 'test-tag-1',
        name: '测试标签',
        color: '#FF0000',
      );

      final result = await repository.deleteTag('test-tag-1');
      expect(result, isA<Ok>());

      final checkResult = await repository.getTagById('test-tag-1');
      expect(checkResult, isA<Ok>());
      expect((checkResult as Ok).value, isNull);
    });

    test('deleteTag - 删除标签后级联清除 ResourceTag', () async {
      // 先创建数据源（外键约束）
      await db.createSource(
        SourcesCompanion.insert(
          id: 'src-1',
          name: '测试源',
          type: SourceType.local,
          rootPath: '/test',
        ),
      );
      // 创建标签和资源关联
      await repository.createTag(id: 'tag-1', name: '标签1', color: '#FF0000');
      await db.createResource(
        ResourcesCompanion.insert(
          id: 'res-1',
          sourceId: 'src-1',
          name: '资源1',
          type: ResourceType.folder,
          relativePath: '/path1',
        ),
      );
      await repository.addTagToResource('res-1', 'tag-1');

      // 删除标签
      final result = await repository.deleteTag('tag-1');
      expect(result, isA<Ok>());

      // 验证关联已被清除
      final tagsResult = await repository.getTagsForResource('res-1');
      expect(tagsResult, isA<Ok>());
      final tags = (tagsResult as Ok).value as List<domain.Tag>;
      expect(tags.isEmpty, true);
    });

    test('updateTag - 内置标签不可修改', () async {
      final tagsResult = await repository.getAllTags();
      final tags = (tagsResult as Ok).value as List<domain.Tag>;
      final builtInTag = tags.first;

      final updatedTag = builtInTag.copyWith(name: '新名称');
      final result = await repository.updateTag(updatedTag);

      expect(result, isA<Err>());
      final error = (result as Err).error;
      expect(error, isA<ValidationError>());
      expect(error.message, contains('内置标签不可修改'));
    });

    group('资源-标签关联', () {
      setUp(() async {
        // 先创建数据源（外键约束）
        await db.createSource(
          SourcesCompanion.insert(
            id: 'src-1',
            name: '测试源',
            type: SourceType.local,
            rootPath: '/test',
          ),
        );
        // 创建测试资源
        await db.createResource(
          ResourcesCompanion.insert(
            id: 'res-1',
            sourceId: 'src-1',
            name: '资源1',
            type: ResourceType.folder,
            relativePath: '/path1',
          ),
        );
        await db.createResource(
          ResourcesCompanion.insert(
            id: 'res-2',
            sourceId: 'src-1',
            name: '资源2',
            type: ResourceType.folder,
            relativePath: '/path2',
          ),
        );
        // 创建测试标签
        await repository.createTag(id: 'tag-1', name: '标签1', color: '#FF0000');
        await repository.createTag(id: 'tag-2', name: '标签2', color: '#00FF00');
        await repository.createTag(id: 'tag-3', name: '标签3', color: '#0000FF');
      });

      test('addTagToResource - 成功关联', () async {
        final result = await repository.addTagToResource('res-1', 'tag-1');
        expect(result, isA<Ok>());

        final tagsResult = await repository.getTagsForResource('res-1');
        expect(tagsResult, isA<Ok>());
        final tags = (tagsResult as Ok).value as List<domain.Tag>;
        expect(tags.length, 1);
        expect(tags.first.id, 'tag-1');
      });

      test('removeTagFromResource - 成功解除关联', () async {
        await repository.addTagToResource('res-1', 'tag-1');
        final result = await repository.removeTagFromResource('res-1', 'tag-1');
        expect(result, isA<Ok>());

        final tagsResult = await repository.getTagsForResource('res-1');
        expect(tagsResult, isA<Ok>());
        final tags = (tagsResult as Ok).value as List<domain.Tag>;
        expect(tags.isEmpty, true);
      });

      test('setTagsForResource - 全量替换标签', () async {
        await repository.addTagToResource('res-1', 'tag-1');
        await repository.addTagToResource('res-1', 'tag-2');

        final result = await repository.setTagsForResource('res-1', [
          'tag-2',
          'tag-3',
        ]);
        expect(result, isA<Ok>());

        final tagsResult = await repository.getTagsForResource('res-1');
        expect(tagsResult, isA<Ok>());
        final tags = (tagsResult as Ok).value as List<domain.Tag>;
        expect(tags.length, 2);
        expect(tags.any((t) => t.id == 'tag-2'), true);
        expect(tags.any((t) => t.id == 'tag-3'), true);
        expect(tags.any((t) => t.id == 'tag-1'), false);
      });

      test('tagResourceCounts - 统计每个标签关联资源数', () async {
        await repository.addTagToResource('res-1', 'tag-1');
        await repository.addTagToResource('res-1', 'tag-2');
        await repository.addTagToResource('res-2', 'tag-1');

        final result = await repository.tagResourceCounts();
        expect(result, isA<Ok>());
        final counts = (result as Ok).value as Map<String, int>;
        expect(counts['tag-1'], 2);
        expect(counts['tag-2'], 1);
        expect(counts.containsKey('tag-3'), false);
      });

      group('filterByTags - 交集筛选', () {
        setUp(() async {
          // res-1: tag-1, tag-2
          await repository.addTagToResource('res-1', 'tag-1');
          await repository.addTagToResource('res-1', 'tag-2');
          // res-2: tag-1
          await repository.addTagToResource('res-2', 'tag-1');
        });

        test('空标签列表返回全部资源', () async {
          final result = await repository.filterByTags([]);
          expect(result, isA<Ok>());
          final resources = (result as Ok).value;
          expect(resources.length, 2);
        });

        test('单标签筛选', () async {
          final result = await repository.filterByTags(['tag-2']);
          expect(result, isA<Ok>());
          final resources = (result as Ok).value;
          expect(resources.length, 1);
          expect(resources.first.id, 'res-1');
        });

        test('多标签交集筛选', () async {
          final result = await repository.filterByTags(['tag-1', 'tag-2']);
          expect(result, isA<Ok>());
          final resources = (result as Ok).value;
          expect(resources.length, 1);
          expect(resources.first.id, 'res-1');
        });

        test('无匹配结果', () async {
          final result = await repository.filterByTags(['tag-3']);
          expect(result, isA<Ok>());
          final resources = (result as Ok).value;
          expect(resources.isEmpty, true);
        });
      });

      test('countFiltered - 筛选结果计数', () async {
        await repository.addTagToResource('res-1', 'tag-1');
        await repository.addTagToResource('res-1', 'tag-2');
        await repository.addTagToResource('res-2', 'tag-1');

        // 空标签返回总数
        final countAll = await repository.countFiltered([]);
        expect(countAll, isA<Ok>());
        expect((countAll as Ok).value, 2);

        // 单标签筛选
        final countTag1 = await repository.countFiltered(['tag-1']);
        expect(countTag1, isA<Ok>());
        expect((countTag1 as Ok).value, 2);

        // 多标签交集
        final countBoth = await repository.countFiltered(['tag-1', 'tag-2']);
        expect(countBoth, isA<Ok>());
        expect((countBoth as Ok).value, 1);
      });
    });
  });
}
