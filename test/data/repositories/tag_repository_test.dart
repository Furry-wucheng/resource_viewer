import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:resource_viewer/data/services/database_service.dart';
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
      // 等待数据库初始化完成（beforeOpen 中会播种内置标签）
      // 通过查询来触发数据库初始化
      final result = await repository.getAllTags();

      expect(result, isA<Ok>());
      final tags = (result as Ok).value as List<domain.Tag>;

      // 应该包含一个内置标签"收藏"
      expect(tags.length, 1);
      expect(tags.first.name, '收藏');
      expect(tags.first.color, '#FFC107');
      expect(tags.first.isBuiltIn, true);
      expect(tags.first.id, '00000000-0000-0000-0000-000000000001');
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
      // 先创建一个标签
      await repository.createTag(
        id: 'test-tag-1',
        name: '测试标签',
        color: '#FF0000',
      );

      // 尝试创建同名标签
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

    test('删除标签 - 内置标签不可删除', () async {
      // 获取内置标签
      final tagsResult = await repository.getAllTags();
      final tags = (tagsResult as Ok).value as List<domain.Tag>;
      final builtInTag = tags.first;

      // 尝试删除内置标签
      final result = await repository.deleteTag(builtInTag.id);

      expect(result, isA<Err>());
      final error = (result as Err).error;
      expect(error, isA<ValidationError>());
      expect(error.message, contains('内置标签不可删除'));

      // 验证标签仍然存在
      final checkResult = await repository.getTagById(builtInTag.id);
      expect(checkResult, isA<Ok>());
      expect((checkResult as Ok).value, isNotNull);
    });

    test('删除标签 - 成功删除自定义标签', () async {
      // 先创建一个标签
      await repository.createTag(
        id: 'test-tag-1',
        name: '测试标签',
        color: '#FF0000',
      );

      // 删除标签
      final result = await repository.deleteTag('test-tag-1');

      expect(result, isA<Ok>());

      // 验证标签已被删除
      final checkResult = await repository.getTagById('test-tag-1');
      expect(checkResult, isA<Ok>());
      expect((checkResult as Ok).value, isNull);
    });

    test('更新标签 - 内置标签不可修改', () async {
      // 获取内置标签
      final tagsResult = await repository.getAllTags();
      final tags = (tagsResult as Ok).value as List<domain.Tag>;
      final builtInTag = tags.first;

      // 尝试更新内置标签
      final updatedTag = builtInTag.copyWith(name: '新名称');
      final result = await repository.updateTag(updatedTag);

      expect(result, isA<Err>());
      final error = (result as Err).error;
      expect(error, isA<ValidationError>());
      expect(error.message, contains('内置标签不可修改'));
    });
  });
}
