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
}
