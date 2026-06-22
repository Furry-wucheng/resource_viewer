import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/domain/models/tag.dart';
import 'package:resource_viewer/ui/features/home/widgets/filter_bar.dart';

void main() {
  Tag createTag({
    required String id,
    required String name,
    required String color,
  }) {
    return Tag(
      id: id,
      name: name,
      color: color,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  group('FilterBar', () {
    testWidgets('显示"全部"和"收藏"按钮', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              customTags: [],
              onAllTap: () {},
              onFavoriteTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('全部'), findsOneWidget);
      expect(find.text('收藏'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('显示自定义标签', (tester) async {
      final tags = [
        createTag(id: '1', name: '热血', color: '#FF0000'),
        createTag(id: '2', name: '科幻', color: '#00FF00'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              customTags: tags,
              onAllTap: () {},
              onFavoriteTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('热血'), findsOneWidget);
      expect(find.text('科幻'), findsOneWidget);
    });

    testWidgets('"全部"默认选中高亮', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              customTags: [],
              isAllSelected: true,
              onAllTap: () {},
              onFavoriteTap: () {},
            ),
          ),
        ),
      );

      // 查找"全部"按钮的容器
      final allChip = find
          .ancestor(of: find.text('全部'), matching: find.byType(Container))
          .first;

      final container = tester.widget<Container>(allChip);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNot(Colors.transparent));
    });

    testWidgets('点击"全部"触发回调', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              customTags: [],
              onAllTap: () => tapped = true,
              onFavoriteTap: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('全部'));
      expect(tapped, true);
    });

    testWidgets('点击"收藏"触发回调', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              customTags: [],
              onAllTap: () {},
              onFavoriteTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('收藏'));
      expect(tapped, true);
    });

    testWidgets('点击自定义标签触发回调', (tester) async {
      String? tappedId;
      final tags = [createTag(id: 'tag-1', name: '热血', color: '#FF0000')];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              customTags: tags,
              selectedTagIds: {},
              onAllTap: () {},
              onFavoriteTap: () {},
              onTagTap: (id) => tappedId = id,
            ),
          ),
        ),
      );

      await tester.tap(find.text('热血'));
      expect(tappedId, 'tag-1');
    });

    testWidgets('选中标签高亮显示', (tester) async {
      final tags = [createTag(id: 'tag-1', name: '热血', color: '#FF0000')];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              customTags: tags,
              selectedTagIds: {'tag-1'},
              onAllTap: () {},
              onFavoriteTap: () {},
            ),
          ),
        ),
      );

      // 查找标签按钮的容器
      final tagChip = find
          .ancestor(of: find.text('热血'), matching: find.byType(Container))
          .first;

      final container = tester.widget<Container>(tagChip);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNot(Colors.transparent));
    });

    testWidgets('未选中标签灰色描边', (tester) async {
      final tags = [createTag(id: 'tag-1', name: '热血', color: '#FF0000')];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              customTags: tags,
              selectedTagIds: {},
              onAllTap: () {},
              onFavoriteTap: () {},
            ),
          ),
        ),
      );

      // 查找标签按钮的容器
      final tagChip = find
          .ancestor(of: find.text('热血'), matching: find.byType(Container))
          .first;

      final container = tester.widget<Container>(tagChip);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.transparent);
    });

    testWidgets('显示筛选结果计数', (tester) async {
      final tags = [createTag(id: 'tag-1', name: '热血', color: '#FF0000')];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              customTags: tags,
              selectedTagIds: {'tag-1'},
              isAllSelected: false,
              filteredCount: 5,
              totalCount: 20,
              onAllTap: () {},
              onFavoriteTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('筛选出 5 / 20 个资源'), findsOneWidget);
    });

    testWidgets('筛选为空时显示提示', (tester) async {
      final tags = [createTag(id: 'tag-1', name: '热血', color: '#FF0000')];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              customTags: tags,
              selectedTagIds: {'tag-1'},
              isAllSelected: false,
              filteredCount: 0,
              totalCount: 20,
              onAllTap: () {},
              onFavoriteTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('筛选出 0 / 20 个资源'), findsOneWidget);
      expect(find.text('试试调整筛选条件'), findsOneWidget);
    });

    testWidgets('选中"全部"时不显示计数', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBar(
              customTags: [],
              isAllSelected: true,
              filteredCount: 20,
              totalCount: 20,
              onAllTap: () {},
              onFavoriteTap: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('筛选出'), findsNothing);
    });
  });
}
