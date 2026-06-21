import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/ui/features/tags/widgets/tag_editor_dialog.dart';

void main() {
  group('TagEditorDialog', () {
    testWidgets('创建模式 - 显示正确的标题', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          home: const SizedBox(), // 需要一个基础页面
        ),
      );

      // 显示弹窗
      final context = tester.element(find.byType(SizedBox));
      showDialog<TagEditorResult>(
        context: context,
        builder: (context) => const TagEditorDialog.create(),
      );
      await tester.pumpAndSettle();

      expect(find.text('新建标签'), findsOneWidget);
    });

    testWidgets('编辑模式 - 显示正确的标题和初始值', (tester) async {
      await tester.pumpWidget(createTestApp(home: const SizedBox()));

      final context = tester.element(find.byType(SizedBox));
      showDialog<TagEditorResult>(
        context: context,
        builder: (context) => const TagEditorDialog.edit(
          initialName: '测试标签',
          initialColor: '#FF0000',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('编辑标签'), findsOneWidget);
      expect(find.text('测试标签'), findsOneWidget);
    });

    testWidgets('空名称时显示错误提示', (tester) async {
      await tester.pumpWidget(createTestApp(home: const SizedBox()));

      final context = tester.element(find.byType(SizedBox));
      showDialog<TagEditorResult>(
        context: context,
        builder: (context) => const TagEditorDialog.create(),
      );
      await tester.pumpAndSettle();

      // 保存按钮应该禁用
      final saveButton = find.widgetWithText(FilledButton, '保存');
      expect(saveButton, findsOneWidget);
      final button = tester.widget<FilledButton>(saveButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('输入名称后保存按钮启用', (tester) async {
      await tester.pumpWidget(createTestApp(home: const SizedBox()));

      final context = tester.element(find.byType(SizedBox));
      showDialog<TagEditorResult>(
        context: context,
        builder: (context) => const TagEditorDialog.create(),
      );
      await tester.pumpAndSettle();

      // 输入名称
      await tester.enterText(find.byType(TextField), '新标签');
      await tester.pump();

      // 保存按钮应该启用
      final saveButton = find.widgetWithText(FilledButton, '保存');
      expect(saveButton, findsOneWidget);
      final button = tester.widget<FilledButton>(saveButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('12 色选择器显示', (tester) async {
      await tester.pumpWidget(createTestApp(home: const SizedBox()));

      final context = tester.element(find.byType(SizedBox));
      showDialog<TagEditorResult>(
        context: context,
        builder: (context) => const TagEditorDialog.create(),
      );
      await tester.pumpAndSettle();

      // 应该有 12 个颜色选择器（检查 Container 的数量）
      // 注意：弹窗本身可能也有 GestureDetector，所以检查 Wrap 中的子项
      expect(find.byType(Wrap), findsOneWidget);
      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(wrap.children.length, 12);
    });

    testWidgets('点击颜色切换选中状态', (tester) async {
      await tester.pumpWidget(createTestApp(home: const SizedBox()));

      final context = tester.element(find.byType(SizedBox));
      showDialog<TagEditorResult>(
        context: context,
        builder: (context) => const TagEditorDialog.create(),
      );
      await tester.pumpAndSettle();

      // 点击第二个颜色
      final colorWidgets = find.byType(GestureDetector);
      await tester.tap(colorWidgets.at(1));
      await tester.pump();

      // 第二个颜色应该有选中标记（check icon）
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}

/// 创建测试用 App
Widget createTestApp({required Widget home}) {
  return MaterialApp(home: home);
}
