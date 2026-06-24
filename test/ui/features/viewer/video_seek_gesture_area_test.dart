import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/ui/features/viewer/widgets/video_seek_gesture_area.dart';

void main() {
  testWidgets('水平拖动按当前位置相对 seek', (tester) async {
    final seeks = <Duration>[];
    final starts = <Duration>[];
    final ends = <Duration>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 180,
            child: VideoSeekGestureArea(
              position: const Duration(seconds: 30),
              duration: const Duration(seconds: 100),
              currentPosition: () => const Duration(seconds: 30),
              onScrubStart: starts.add,
              onScrubUpdate: seeks.add,
              onScrubEnd: ends.add,
            ),
          ),
        ),
      ),
    );

    final zone = find.byKey(const ValueKey('video-seek-zone'));

    // 水平拖动触发 seek，从 currentPosition 开始相对偏移。
    await tester.drag(zone, const Offset(100, 0));
    await tester.pump();

    expect(starts, [const Duration(seconds: 30)]);
    expect(seeks, isNotEmpty);
    expect(ends, isNotEmpty);
    expect(ends.last, seeks.last);
    // 100px 拖动 / 400px 宽 * 100s 时长 = 25s 偏移；起点 30s → 落点约 55s。
    // 累计 delta 必须得到完整偏移（旧 bug 只取末帧增量，落点仅 ~31s，
    // 会被下界 >50s 拦下）。
    expect(seeks.last, greaterThan(const Duration(seconds: 50)));
    expect(seeks.last, lessThan(const Duration(seconds: 60)));
  });

  testWidgets('拖动起点使用实时播放位置而不是传入的旧显示位置', (tester) async {
    final starts = <Duration>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 180,
            child: VideoSeekGestureArea(
              position: const Duration(seconds: 80),
              duration: const Duration(seconds: 100),
              currentPosition: () => const Duration(seconds: 42),
              onScrubStart: starts.add,
              onScrubUpdate: (_) {},
              onScrubEnd: (_) {},
            ),
          ),
        ),
      ),
    );

    final zone = find.byKey(const ValueKey('video-seek-zone'));
    await tester.drag(zone, const Offset(100, 0));
    await tester.pump();

    expect(starts, [const Duration(seconds: 42)]);
  });

  testWidgets('duration 为零时禁用所有拖动', (tester) async {
    final starts = <Duration>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 180,
            child: VideoSeekGestureArea(
              position: Duration.zero,
              duration: Duration.zero,
              currentPosition: () => Duration.zero,
              onScrubStart: starts.add,
              onScrubUpdate: (_) {},
              onScrubEnd: (_) {},
            ),
          ),
        ),
      ),
    );

    final zone = find.byKey(const ValueKey('video-seek-zone'));
    await tester.drag(zone, const Offset(100, 0));
    await tester.pump();

    expect(starts, isEmpty);
  });

  testWidgets('小幅水平移动不超过门槛时不触发 scrub', (tester) async {
    final starts = <Duration>[];
    final updates = <Duration>[];
    final ends = <Duration>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 180,
            child: VideoSeekGestureArea(
              position: const Duration(seconds: 30),
              duration: const Duration(seconds: 100),
              currentPosition: () => const Duration(seconds: 30),
              onScrubStart: starts.add,
              onScrubUpdate: updates.add,
              onScrubEnd: ends.add,
            ),
          ),
        ),
      ),
    );

    final zone = find.byKey(const ValueKey('video-seek-zone'));
    // 10px < 18px 门槛 → 不应进入 scrubbing。
    await tester.drag(zone, const Offset(10, 0));
    await tester.pump();

    expect(starts, isEmpty);
    expect(updates, isEmpty);
    expect(ends, isEmpty);
  });
}
