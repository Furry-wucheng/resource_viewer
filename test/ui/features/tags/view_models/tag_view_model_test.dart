import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:resource_viewer/data/services/database_service.dart';
import 'package:resource_viewer/data/repositories/tag_repository.dart';
import 'package:resource_viewer/ui/core/view_models/base_view_model.dart';
import 'package:resource_viewer/ui/features/tags/view_models/tag_view_model.dart';

void main() {
  late AppDatabase db;
  late TagRepository repository;
  late TagViewModel viewModel;
  late List<UiState> stateChanges;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = TagRepository(db);
    viewModel = TagViewModel(tagRepository: repository);
    stateChanges = [];
    viewModel.addListener(() {
      stateChanges.add(viewModel.state);
    });
  });

  tearDown(() async {
    viewModel.dispose();
    await db.close();
  });

  group('TagViewModel', () {
    test('loadTags - 成功加载标签列表', () async {
      await viewModel.loadTags();

      expect(viewModel.state, UiState.success);
      expect(viewModel.tags.length, 1); // 内置标签"收藏"
      expect(viewModel.builtInTags.length, 1);
      expect(viewModel.customTags.isEmpty, true);
    });

    test('loadTags - 状态转换 loading → success', () async {
      await viewModel.loadTags();

      expect(stateChanges, [UiState.loading, UiState.success]);
    });

    test('createTag - 成功创建标签后刷新列表', () async {
      await viewModel.loadTags();

      final tag = await viewModel.createTag(name: '测试标签', color: '#FF0000');

      expect(tag, isNotNull);
      expect(tag!.name, '测试标签');
      expect(viewModel.customTags.length, 1);
      expect(viewModel.customTags.first.name, '测试标签');
    });

    test('createTag - 标签名为空返回 null', () async {
      await viewModel.loadTags();

      final tag = await viewModel.createTag(name: '', color: '#FF0000');

      expect(tag, isNull);
      expect(viewModel.customTags.isEmpty, true);
    });

    test('createTag - 标签名重复返回 null', () async {
      await viewModel.loadTags();
      await viewModel.createTag(name: '测试标签', color: '#FF0000');

      final tag = await viewModel.createTag(name: '测试标签', color: '#00FF00');

      expect(tag, isNull);
      expect(viewModel.customTags.length, 1);
    });

    test('renameTag - 成功重命名标签', () async {
      await viewModel.loadTags();
      final created = await viewModel.createTag(name: '原名称', color: '#FF0000');

      final updated = await viewModel.renameTag(created!.id, '新名称');

      expect(updated, isNotNull);
      expect(updated!.name, '新名称');
      expect(viewModel.customTags.first.name, '新名称');
    });

    test('renameTag - 内置标签不可重命名', () async {
      await viewModel.loadTags();
      final builtInTag = viewModel.builtInTags.first;

      final result = await viewModel.renameTag(builtInTag.id, '新名称');

      expect(result, isNull);
    });

    test('renameTag - 重命名为已存在的名称返回 null', () async {
      await viewModel.loadTags();
      await viewModel.createTag(name: '标签1', color: '#FF0000');
      await viewModel.createTag(name: '标签2', color: '#00FF00');

      final tag1 = viewModel.customTags.firstWhere((t) => t.name == '标签1');
      final result = await viewModel.renameTag(tag1.id, '标签2');

      expect(result, isNull);
    });

    test('updateColor - 成功修改标签颜色', () async {
      await viewModel.loadTags();
      final created = await viewModel.createTag(name: '测试标签', color: '#FF0000');

      final updated = await viewModel.updateColor(created!.id, '#00FF00');

      expect(updated, isNotNull);
      expect(updated!.color, '#00FF00');
      expect(viewModel.customTags.first.color, '#00FF00');
    });

    test('deleteTag - 成功删除自定义标签', () async {
      await viewModel.loadTags();
      await viewModel.createTag(name: '测试标签', color: '#FF0000');

      final tag = viewModel.customTags.first;
      final result = await viewModel.deleteTag(tag.id);

      expect(result, true);
      expect(viewModel.customTags.isEmpty, true);
    });

    test('deleteTag - 内置标签不可删除', () async {
      await viewModel.loadTags();
      final builtInTag = viewModel.builtInTags.first;

      final result = await viewModel.deleteTag(builtInTag.id);

      expect(result, false);
      expect(viewModel.builtInTags.length, 1);
    });

    group('validateTagName', () {
      setUp(() async {
        await viewModel.loadTags();
      });

      test('空名称返回错误', () {
        final result = viewModel.validateTagName('');
        expect(result, isNotNull);
        expect(result, contains('不能为空'));
      });

      test('全空格名称返回错误', () {
        final result = viewModel.validateTagName('   ');
        expect(result, isNotNull);
        expect(result, contains('不能为空'));
      });

      test('与内置标签同名返回错误', () {
        final result = viewModel.validateTagName('收藏');
        expect(result, isNotNull);
        expect(result, contains('内置标签'));
      });

      test('重复名称返回错误', () async {
        await viewModel.createTag(name: '测试标签', color: '#FF0000');

        final result = viewModel.validateTagName('测试标签');
        expect(result, isNotNull);
        expect(result, contains('已存在'));
      });

      test('超长名称返回错误', () {
        final result = viewModel.validateTagName('123456789012345678901');
        expect(result, isNotNull);
        expect(result, contains('不能超过'));
      });

      test('恰好 20 个字符有效', () {
        final result = viewModel.validateTagName('12345678901234567890');
        expect(result, isNull);
      });

      test('有效名称返回 null', () {
        final result = viewModel.validateTagName('有效标签名');
        expect(result, isNull);
      });

      test('排除自身 ID 后不报重复', () async {
        await viewModel.createTag(name: '测试标签', color: '#FF0000');
        final tag = viewModel.customTags.first;

        final result = viewModel.validateTagName('测试标签', excludeId: tag.id);
        expect(result, isNull);
      });
    });

    test('getUsedColors - 返回已使用的颜色列表', () async {
      await viewModel.loadTags();
      await viewModel.createTag(name: '标签1', color: '#FF0000');
      await viewModel.createTag(name: '标签2', color: '#00FF00');

      final colors = viewModel.getUsedColors();

      expect(colors.length, 3); // 内置标签 + 2 个自定义标签
      expect(colors.contains('#FFC107'), true); // 内置标签颜色
      expect(colors.contains('#FF0000'), true);
      expect(colors.contains('#00FF00'), true);
    });

    test('getFirstUnusedColor - 返回第一个未使用的颜色', () async {
      await viewModel.loadTags();
      await viewModel.createTag(name: '标签1', color: '#FF0000');

      final presetColors = ['#FF0000', '#00FF00', '#0000FF'];
      final color = viewModel.getFirstUnusedColor(presetColors);

      expect(color, '#00FF00');
    });
  });
}
