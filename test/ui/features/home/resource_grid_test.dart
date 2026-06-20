import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:resource_viewer/domain/models/resource.dart';
import 'package:resource_viewer/ui/features/home/widgets/resource_grid.dart';
import 'package:resource_viewer/ui/features/home/widgets/resource_grid_item.dart';

class _CountingNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }
}

void main() {
  testWidgets('空状态可跳转到数据源', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResourceGrid(
            resources: const [],
            onAddSource: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('还没有资源'), findsOneWidget);
    await tester.tap(find.text('去添加数据源'));
    expect(tapped, isTrue);
  });

  testWidgets('网格使用验收要求的虚拟化参数', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime(2026);
    final resources = List.generate(
      12,
      (index) => Resource(
        id: '$index',
        sourceId: 'source',
        name: '资源 $index',
        type: ResourceType.folder,
        relativePath: '$index',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ResourceGrid(resources: resources))),
    );

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate = grid.gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent;
    expect(delegate.maxCrossAxisExtent, 180);
    expect(delegate.childAspectRatio, 2 / 3);
    expect(grid.scrollCacheExtent, const ScrollCacheExtent.pixels(1500));
  });

  testWidgets('快速双击资源只会打开一个查看器路由', (tester) async {
    final observer = _CountingNavigatorObserver();
    final now = DateTime(2026);
    final resource = Resource(
      id: 'resource-1',
      sourceId: 'source',
      name: '测试资源',
      type: ResourceType.folder,
      relativePath: 'resource-1',
      createdAt: now,
      updatedAt: now,
    );
    final router = GoRouter(
      observers: [observer],
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: ResourceGrid(resources: [resource]),
          ),
        ),
        GoRoute(
          path: '/viewer/:resourceId',
          builder: (_, _) => const Scaffold(body: Text('查看器')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    final pushesBeforeTap = observer.pushCount;
    final item = find.byType(ResourceGridItem);

    await tester.tap(item);
    await tester.tap(item);
    await tester.pumpAndSettle();

    expect(find.text('查看器'), findsOneWidget);
    expect(observer.pushCount - pushesBeforeTap, 1);

    router.pop();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    await tester.tap(item);
    await tester.pumpAndSettle();

    expect(find.text('查看器'), findsOneWidget);
    expect(observer.pushCount - pushesBeforeTap, 2);
  });
}
