import 'package:flutter/material.dart';

/// 视频底部的大范围进度拖动热区。
///
/// 轻点不会跳转；只有形成水平拖动后，才以拖动开始时的播放位置为基准
/// 相对调整进度，避免按下瞬间跳到 0。
class VideoSeekGestureArea extends StatefulWidget {
  const VideoSeekGestureArea({
    super.key,
    required this.position,
    required this.duration,
    required this.onScrubStart,
    required this.onScrubUpdate,
    required this.onScrubEnd,
    this.onTap,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onScrubStart;
  final ValueChanged<Duration> onScrubUpdate;
  final ValueChanged<Duration> onScrubEnd;
  final VoidCallback? onTap;

  @override
  State<VideoSeekGestureArea> createState() => _VideoSeekGestureAreaState();
}

class _VideoSeekGestureAreaState extends State<VideoSeekGestureArea> {
  Duration _dragStartPosition = Duration.zero;
  Duration _latestPosition = Duration.zero;
  double _dragDistance = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        key: const ValueKey('video-seek-zone'),
        behavior: HitTestBehavior.translucent,
        excludeFromSemantics: true,
        onTap: widget.onTap,
        onHorizontalDragStart: widget.duration == Duration.zero
            ? null
            : (_) {
                _dragStartPosition = widget.position;
                _latestPosition = widget.position;
                _dragDistance = 0;
                widget.onScrubStart(widget.position);
              },
        onHorizontalDragUpdate: widget.duration == Duration.zero
            ? null
            : (details) {
                _dragDistance += details.primaryDelta ?? 0;
                final width = constraints.maxWidth;
                if (width <= 0) return;
                final delta =
                    widget.duration.inMilliseconds * (_dragDistance / width);
                final targetMs = (_dragStartPosition.inMilliseconds + delta)
                    .round()
                    .clamp(0, widget.duration.inMilliseconds);
                _latestPosition = Duration(milliseconds: targetMs);
                widget.onScrubUpdate(_latestPosition);
              },
        onHorizontalDragEnd: widget.duration == Duration.zero
            ? null
            : (_) => widget.onScrubEnd(_latestPosition),
        onHorizontalDragCancel: widget.duration == Duration.zero
            ? null
            : () => widget.onScrubEnd(_latestPosition),
      ),
    );
  }
}
