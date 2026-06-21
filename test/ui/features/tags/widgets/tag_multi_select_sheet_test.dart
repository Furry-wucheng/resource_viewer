import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:provider/provider.dart';
import 'package:resource_viewer/data/services/database_service.dart';
import 'package:resource_viewer/data/repositories/tag_repository.dart';
import 'package:resource_viewer/ui/features/tags/widgets/tag_multi_select_sheet.dart';

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

  Widget createTestApp({Set<String> selectedTagIds = const {}}) {
    return MultiProvider(
      providers: [Provider<TagRepository>.value(value: repository)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    TagMultiSelectSheet.show(
                      context: context,
                      selectedTagIds: selectedTagIds,
                    );
                  },
                  child: const Text('打开'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  group('TagMultiSelectSheet', () {
    testWidgets('显示标题', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // 打开弹窗
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();

      expect(find.text('选择标签'), findsOneWidget);
    });

    testWidgets('显示内置标签"收藏"', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();

      expect(find.text('收藏'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('显示自定义标签', (tester) async {
      await repository.createTag(id: 'tag-1', name: '测试标签', color: '#FF0000');

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();

      expect(find.text('测试标签'), findsOneWidget);
    });

    testWidgets('已选标签显示勾选状态', (tester) async {
      await tester.pumpWidget(
        createTestApp(selectedTagIds: {'00000000-0000-0000-0000-000000000001'}),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();

      // 内置标签应该被选中
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(checkbox.value, true);
    });

    testWidgets('点击标签切换勾选状态', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();

      // 初始未选中
      final checkboxBefore = tester.widget<Checkbox>(
        find.byType(Checkbox).first,
      );
      expect(checkboxBefore.value, false);

      // 点击标签
      await tester.tap(find.text('收藏'));
      await tester.pump();

      // 应该变为选中
      final checkboxAfter = tester.widget<Checkbox>(
        find.byType(Checkbox).first,
      );
      expect(checkboxAfter.value, true);
    });

    testWidgets('显示新建标签按钮', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();

      expect(find.text('新建标签'), findsOneWidget);
    });

    testWidgets('显示确认和取消按钮', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();

      expect(find.text('确认'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
    });

    testWidgets('显示已选数量', (tester) async {
      await tester.pumpWidget(
        createTestApp(selectedTagIds: {'00000000-0000-0000-0000-000000000001'}),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();

      expect(find.text('已选 1 个'), findsOneWidget);
    });

    testWidgets('无自定义标签时显示空状态', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();

      expect(find.text('暂无自定义标签'), findsOneWidget);
    });
  });
}
