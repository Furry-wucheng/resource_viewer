import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:provider/provider.dart';
import 'package:resource_viewer/data/services/database_service.dart';
import 'package:resource_viewer/data/repositories/tag_repository.dart';
import 'package:resource_viewer/ui/features/tags/tag_manager_page.dart';

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

  Widget createTestApp() {
    return MaterialApp(
      home: MultiProvider(
        providers: [Provider<TagRepository>.value(value: repository)],
        child: const TagManagerPage(),
      ),
    );
  }

  group('TagManagerPage', () {
    testWidgets('显示标题和新建标签按钮', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('标签管理'), findsOneWidget);
      // AppBar 中的 TextButton.icon 包含文本
      expect(find.text('新建标签'), findsWidgets);
    });

    testWidgets('显示内置标签"收藏"', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('收藏'), findsOneWidget);
      expect(find.text('内置'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('内置标签区域标题显示', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('内置标签'), findsOneWidget);
    });

    testWidgets('无自定义标签时显示空状态', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('创建第一个标签吧'), findsOneWidget);
      expect(find.text('自定义标签'), findsNothing);
    });

    testWidgets('有自定义标签时显示标签列表', (tester) async {
      // 创建自定义标签
      await repository.createTag(id: 'tag-1', name: '测试标签', color: '#FF0000');

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('测试标签'), findsOneWidget);
      expect(find.text('自定义标签'), findsOneWidget);
      expect(find.text('创建第一个标签吧'), findsNothing);
    });

    testWidgets('自定义标签显示关联资源数', (tester) async {
      // 创建自定义标签
      await repository.createTag(id: 'tag-1', name: '测试标签', color: '#FF0000');

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // 内置标签和自定义标签都会显示资源数
      expect(find.textContaining('个资源'), findsWidgets);
    });

    testWidgets('自定义标签显示操作菜单图标', (tester) async {
      // 创建自定义标签
      await repository.createTag(id: 'tag-1', name: '测试标签', color: '#FF0000');

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });

    testWidgets('点击新建标签按钮弹出编辑弹窗', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // 点击 AppBar 中的 TextButton
      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();

      // 应该显示弹窗
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('点击自定义标签的操作菜单显示选项', (tester) async {
      // 创建自定义标签
      await repository.createTag(id: 'tag-1', name: '测试标签', color: '#FF0000');

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // 点击操作菜单
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();

      // 应该显示菜单选项
      expect(find.text('重命名'), findsOneWidget);
      expect(find.text('修改颜色'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
    });
  });
}
