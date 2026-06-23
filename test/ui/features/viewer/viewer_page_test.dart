import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';

import 'package:resource_viewer/shared/content_provider/content_provider.dart';
import 'package:resource_viewer/ui/features/viewer/viewer_page.dart';
import 'package:resource_viewer/ui/features/viewer/widgets/slide_bar.dart';
import 'package:resource_viewer/ui/features/viewer/widgets/viewer_toolbar.dart';

// 1x1 最小 JPEG 字节
final kMinimalJpeg = Uint8List.fromList([
  0xFF,
  0xD8,
  0xFF,
  0xE0,
  0x00,
  0x10,
  0x4A,
  0x46,
  0x49,
  0x46,
  0x00,
  0x01,
  0x01,
  0x00,
  0x00,
  0x01,
  0x00,
  0x01,
  0x00,
  0x00,
  0xFF,
  0xDB,
  0x00,
  0x43,
  0x00,
  0x08,
  0x06,
  0x06,
  0x07,
  0x06,
  0x05,
  0x08,
  0x07,
  0x07,
  0x07,
  0x09,
  0x09,
  0x08,
  0x0A,
  0x0C,
  0x14,
  0x0D,
  0x0C,
  0x0B,
  0x0B,
  0x0C,
  0x19,
  0x12,
  0x13,
  0x0F,
  0x14,
  0x1D,
  0x1A,
  0x1F,
  0x1E,
  0x1D,
  0x1A,
  0x1C,
  0x1C,
  0x20,
  0x24,
  0x2E,
  0x27,
  0x20,
  0x22,
  0x2C,
  0x23,
  0x1C,
  0x1C,
  0x28,
  0x37,
  0x29,
  0x2C,
  0x30,
  0x31,
  0x34,
  0x34,
  0x34,
  0x1F,
  0x27,
  0x39,
  0x3D,
  0x38,
  0x32,
  0x3C,
  0x2E,
  0x33,
  0x34,
  0x32,
  0xFF,
  0xC0,
  0x00,
  0x0B,
  0x08,
  0x00,
  0x01,
  0x00,
  0x01,
  0x01,
  0x01,
  0x11,
  0x00,
  0xFF,
  0xC4,
  0x00,
  0x1F,
  0x00,
  0x00,
  0x01,
  0x05,
  0x01,
  0x01,
  0x01,
  0x01,
  0x01,
  0x01,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x01,
  0x02,
  0x03,
  0x04,
  0x05,
  0x06,
  0x07,
  0x08,
  0x09,
  0x0A,
  0x0B,
  0xFF,
  0xC4,
  0x00,
  0xB5,
  0x10,
  0x00,
  0x02,
  0x01,
  0x03,
  0x03,
  0x02,
  0x04,
  0x03,
  0x05,
  0x05,
  0x04,
  0x04,
  0x00,
  0x00,
  0x01,
  0x7D,
  0x01,
  0x02,
  0x03,
  0x00,
  0x04,
  0x11,
  0x05,
  0x12,
  0x21,
  0x31,
  0x41,
  0x06,
  0x13,
  0x51,
  0x61,
  0x07,
  0x22,
  0x71,
  0x14,
  0x32,
  0x81,
  0x91,
  0xA1,
  0x08,
  0x23,
  0x42,
  0xB1,
  0xC1,
  0x15,
  0x52,
  0xD1,
  0xF0,
  0x24,
  0x33,
  0x62,
  0x72,
  0x82,
  0x09,
  0x0A,
  0x16,
  0x17,
  0x18,
  0x19,
  0x1A,
  0x25,
  0x26,
  0x27,
  0x28,
  0x29,
  0x2A,
  0x34,
  0x35,
  0x36,
  0x37,
  0x38,
  0x39,
  0x3A,
  0x43,
  0x44,
  0x45,
  0x46,
  0x47,
  0x48,
  0x49,
  0x4A,
  0x53,
  0x54,
  0x55,
  0x56,
  0x57,
  0x58,
  0x59,
  0x5A,
  0x63,
  0x64,
  0x65,
  0x66,
  0x67,
  0x68,
  0x69,
  0x6A,
  0x73,
  0x74,
  0x75,
  0x76,
  0x77,
  0x78,
  0x79,
  0x7A,
  0x83,
  0x84,
  0x85,
  0x86,
  0x87,
  0x88,
  0x89,
  0x8A,
  0x92,
  0x93,
  0x94,
  0x95,
  0x96,
  0x97,
  0x98,
  0x99,
  0x9A,
  0xA2,
  0xA3,
  0xA4,
  0xA5,
  0xA6,
  0xA7,
  0xA8,
  0xA9,
  0xAA,
  0xB2,
  0xB3,
  0xB4,
  0xB5,
  0xB6,
  0xB7,
  0xB8,
  0xB9,
  0xBA,
  0xC2,
  0xC3,
  0xC4,
  0xC5,
  0xC6,
  0xC7,
  0xC8,
  0xC9,
  0xCA,
  0xD2,
  0xD3,
  0xD4,
  0xD5,
  0xD6,
  0xD7,
  0xD8,
  0xD9,
  0xDA,
  0xE1,
  0xE2,
  0xE3,
  0xE4,
  0xE5,
  0xE6,
  0xE7,
  0xE8,
  0xE9,
  0xEA,
  0xF1,
  0xF2,
  0xF3,
  0xF4,
  0xF5,
  0xF6,
  0xF7,
  0xF8,
  0xF9,
  0xFA,
  0xFF,
  0xDA,
  0x00,
  0x08,
  0x01,
  0x01,
  0x00,
  0x00,
  0x3F,
  0x00,
  0x7B,
  0x94,
  0x11,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0xFF,
  0xD9,
]);

class MockContentProvider extends Mock implements ContentProvider {}

void main() {
  group('ViewerPage', () {
    late MockContentProvider mockProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockProvider = MockContentProvider();
      when(() => mockProvider.pageCount).thenReturn(3);
      when(
        () => mockProvider.loadPage(any()),
      ).thenAnswer((_) async => kMinimalJpeg);
      when(() => mockProvider.dispose()).thenAnswer((_) async {});
    });

    tearDown(() {
      // 不 reset，setUp 每次创建新实例
    });

    Widget buildViewer() {
      return MaterialApp(
        home: ViewerPage(title: 'Test Resource', contentProvider: mockProvider),
      );
    }

    testWidgets('显示工具栏和滑动条', (tester) async {
      await tester.pumpWidget(buildViewer());
      await tester.pumpAndSettle();

      // 工具栏应可见
      expect(find.byType(ViewerToolbar), findsOneWidget);
      expect(find.text('Test Resource'), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);

      // 滑动条应可见（多页时）
      expect(find.byType(SlideBar), findsOneWidget);
    });

    testWidgets('单击切换工具栏显隐', (tester) async {
      await tester.pumpWidget(buildViewer());
      await tester.pumpAndSettle();

      // 初始状态：工具栏可见
      expect(find.byType(ViewerToolbar), findsOneWidget);

      // 单击屏幕中央区域（避开工具栏和滑动条）
      await tester.tapAt(const Offset(200, 250));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // 工具栏隐藏
      expect(find.byType(ViewerToolbar), findsNothing);

      // 再次单击显示
      await tester.tapAt(const Offset(200, 250));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byType(ViewerToolbar), findsOneWidget);
    });

    testWidgets('左右点击区翻页且中间点击区控制工具栏', (tester) async {
      await tester.pumpWidget(buildViewer());
      await tester.pumpAndSettle();

      final size = tester.getSize(
        find.byKey(const ValueKey('viewer-interaction-layer')),
      );
      await tester.tapAt(Offset(size.width * 0.1, size.height * 0.5));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.byType(ViewerToolbar), findsOneWidget);

      await tester.tapAt(Offset(size.width * 0.9, size.height * 0.5));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);

      await tester.tapAt(Offset(size.width * 0.5, size.height * 0.5));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.byType(ViewerToolbar), findsNothing);
    });

    testWidgets('顶部返回按钮不被图片手势层覆盖', (tester) async {
      await tester.pumpWidget(buildViewer());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(tester.takeException(), isNull);
      // 根路由无法继续 pop，但按钮应收到点击，不能被下层中间点击区隐藏。
      expect(find.byType(ViewerToolbar), findsOneWidget);
    });

    testWidgets('默认 RTL 右滑下一页', (tester) async {
      await tester.pumpWidget(buildViewer());
      await tester.pumpAndSettle();

      // 初始状态：工具栏可见，显示 1 / 3
      expect(find.text('1 / 3'), findsOneWidget);

      // 先隐藏工具栏（单击切换）
      await tester.tapAt(const Offset(200, 250));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.byType(ViewerToolbar), findsNothing);

      // 默认 RTL：向右拖动，当前图向右移动 → 下一页
      await tester.fling(
        find.byKey(const ValueKey('viewer-page-view')),
        const Offset(300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // 显示工具栏查看页码
      await tester.tapAt(const Offset(200, 250));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // 应显示第 2 页
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('资源库翻页使用跟手 PageView 动画', (tester) async {
      SharedPreferences.setMockInitialValues({'page_direction': 1});
      await tester.pumpWidget(buildViewer());
      await tester.pumpAndSettle();

      final pageViewFinder = find.byKey(const ValueKey('viewer-page-view'));
      final pageView = tester.widget<PageView>(pageViewFinder);
      final gesture = await tester.startGesture(
        tester.getCenter(pageViewFinder),
      );
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-140, 0));
      await tester.pump();

      expect(pageView.controller!.page, greaterThan(0));
      expect(pageView.controller!.page, lessThan(1));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('翻页方向同时控制手势轴和动画轴', (tester) async {
      await tester.pumpWidget(buildViewer());
      await tester.pumpAndSettle();
      var pageView = tester.widget<PageView>(
        find.byKey(const ValueKey('viewer-page-view')),
      );
      expect(pageView.reverse, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      SharedPreferences.setMockInitialValues({'page_direction': 1});
      await tester.pumpWidget(buildViewer());
      await tester.pumpAndSettle();
      pageView = tester.widget<PageView>(
        find.byKey(const ValueKey('viewer-page-view')),
      );
      expect(pageView.reverse, isFalse, reason: '物理动画轴不随阅读模式反转');
      final controller = pageView.controller!;
      expect(controller.page, 0);
      await tester.fling(
        find.byKey(const ValueKey('viewer-page-view')),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);

      await tester.fling(
        find.byKey(const ValueKey('viewer-page-view')),
        const Offset(300, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('宽屏双页模式按首页单页后每次两页显示', (tester) async {
      when(() => mockProvider.pageCount).thenReturn(5);
      SharedPreferences.setMockInitialValues({'double_page_mode': 2});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildViewer());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('viewer-double-page-view')),
        findsOneWidget,
      );
      expect(find.text('1 / 5'), findsOneWidget);

      await tester.fling(
        find.byKey(const ValueKey('viewer-double-page-view')),
        const Offset(400, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('2 / 5'), findsOneWidget);

      final size = tester.getSize(
        find.byKey(const ValueKey('viewer-interaction-layer')),
      );
      await tester.tapAt(Offset(size.width * 0.1, size.height * 0.5));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('4 / 5'), findsOneWidget);
    });

    testWidgets('双页模式无法配对的末页居中单独显示', (tester) async {
      when(() => mockProvider.pageCount).thenReturn(4);
      SharedPreferences.setMockInitialValues({'double_page_mode': 2});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildViewer());
      await tester.pumpAndSettle();
      final size = tester.getSize(
        find.byKey(const ValueKey('viewer-interaction-layer')),
      );
      for (var i = 0; i < 2; i++) {
        await tester.tapAt(Offset(size.width * 0.1, size.height * 0.5));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
      }

      expect(find.text('4 / 4'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('viewer-singleton-spread-3')),
        findsOneWidget,
      );
    });

    testWidgets('默认 RTL 左滑上一页', (tester) async {
      await tester.pumpWidget(buildViewer());
      await tester.pumpAndSettle();

      // 先隐藏工具栏
      await tester.tapAt(const Offset(200, 250));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // 默认 RTL：右滑到第 2 页
      await tester.fling(
        find.byKey(const ValueKey('viewer-page-view')),
        const Offset(300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // 左滑 → 上一页
      await tester.fling(
        find.byKey(const ValueKey('viewer-page-view')),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // 显示工具栏查看页码
      await tester.tapAt(const Offset(200, 250));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // 应回到第 1 页
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('滑动条跳转页面', (tester) async {
      await tester.pumpWidget(buildViewer());
      await tester.pumpAndSettle();

      // 找到滑动条
      final slider = find.byType(SlideBar);
      expect(slider, findsOneWidget);

      // 拖动滑动条到右侧（足够大的距离）
      await tester.drag(slider, const Offset(-500, 0));
      await tester.pumpAndSettle();

      // 应跳转到最后一页
      expect(find.text('3 / 3'), findsOneWidget);
    });

    testWidgets('加载失败显示重试按钮', (tester) async {
      // 让第 2 页加载失败
      var callCount = 0;
      when(() => mockProvider.loadPage(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 2) {
          throw Exception('Load failed');
        }
        return kMinimalJpeg;
      });

      await tester.pumpWidget(buildViewer());
      await tester.pumpAndSettle();

      // 先隐藏工具栏
      await tester.tapAt(const Offset(200, 250));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // 默认 RTL：右滑到第 2 页
      await tester.fling(
        find.byKey(const ValueKey('viewer-page-view')),
        const Offset(300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // 应显示错误提示和重试按钮
      expect(find.text('加载失败'), findsOneWidget);
      expect(find.byIcon(Icons.broken_image), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('单页资源不显示滑动条', (tester) async {
      when(() => mockProvider.pageCount).thenReturn(1);

      await tester.pumpWidget(buildViewer());
      await tester.pumpAndSettle();

      // 滑动条不显示
      expect(find.byType(SlideBar), findsNothing);
      expect(find.text('1 / 1'), findsOneWidget);
    });

    testWidgets('加载尚未完成时退出不会在销毁后刷新', (tester) async {
      final completer = Completer<Uint8List>();
      when(
        () => mockProvider.loadPage(any()),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildViewer());
      await tester.pump();
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();

      completer.complete(kMinimalJpeg);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      verify(() => mockProvider.dispose()).called(1);
    });

    testWidgets('连续进入退出查看器时每个 Provider 仅释放一次', (tester) async {
      for (var i = 0; i < 5; i++) {
        final provider = MockContentProvider();
        when(() => provider.pageCount).thenReturn(1);
        when(
          () => provider.loadPage(any()),
        ).thenAnswer((_) async => kMinimalJpeg);
        when(() => provider.dispose()).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: ViewerPage(title: 'Viewer $i', contentProvider: provider),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        await tester.pumpAndSettle();

        verify(() => provider.dispose()).called(1);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('工具栏重建不会重复读取当前页', (tester) async {
      await tester.pumpWidget(buildViewer());
      await tester.pumpAndSettle();

      for (var i = 0; i < 4; i++) {
        await tester.tapAt(const Offset(400, 250));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
      }

      // 初始化窗口仅包含 0、1、2 三页；UI 重建不能触发额外读取。
      verify(() => mockProvider.loadPage(any())).called(3);
      expect(tester.takeException(), isNull);
    });
  });
}
