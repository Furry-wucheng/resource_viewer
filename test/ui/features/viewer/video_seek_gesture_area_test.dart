import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resource_viewer/ui/features/viewer/widgets/video_seek_gesture_area.dart';

void main() {
  testWidgets('轻点热区不改变进度，水平拖动按当前位置相对 seek', (tester) async {
    final seeks = <Duration>[];
    final starts = <Duration>[];
    final ends = <Duration>[];
    var taps = 0;

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
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );

    final zone = find.byKey(const ValueKey('video-seek-zone'));
    await tester.tap(zone);
    await tester.pump();

    expect(taps, 1);
    expect(seeks, isEmpty);

    await tester.drag(zone, const Offset(100, 0));
    await tester.pump();

    expect(seeks, isNotEmpty);
    expect(starts, [const Duration(seconds: 30)]);
    expect(ends, isNotEmpty);
    expect(ends.last, seeks.last);
    expect(seeks.last, greaterThan(const Duration(seconds: 30)));
    expect(seeks.last, lessThan(const Duration(seconds: 60)));
  });

  testWidgets('长按热区触发自身倍速手势且不会冒泡到父级', (tester) async {
    var parentLongPresses = 0;
    var childLongPresses = 0;
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: GestureDetector(
            onLongPressStart: (_) => parentLongPresses++,
            child: SizedBox(
              width: 400,
              height: 180,
              child: VideoSeekGestureArea(
                position: const Duration(seconds: 30),
                duration: const Duration(seconds: 100),
                currentPosition: () => const Duration(seconds: 30),
                onScrubStart: (_) {},
                onScrubUpdate: (_) {},
                onScrubEnd: (_) {},
                onTap: () => taps++,
                onLongPressStart: (_) => childLongPresses++,
              ),
            ),
          ),
        ),
      ),
    );

    final zone = find.byKey(const ValueKey('video-seek-zone'));
    await tester.longPress(zone);
    await tester.pump();

    expect(parentLongPresses, 0);
    expect(childLongPresses, 1);
    expect(taps, 0);
  });

  testWidgets('小幅移动不会启动拖动跳转', (tester) async {
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
              position: const Duration(seconds: 80),
              duration: const Duration(seconds: 100),
              currentPosition: () => const Duration(seconds: 42),
              onScrubStart: starts.add,
              onScrubUpdate: updates.add,
              onScrubEnd: ends.add,
            ),
          ),
        ),
      ),
    );

    final zone = find.byKey(const ValueKey('video-seek-zone'));
    await tester.drag(zone, const Offset(10, 2));
    await tester.pump();

    expect(starts, isEmpty);
    expect(updates, isEmpty);
    expect(ends, isEmpty);
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
}
