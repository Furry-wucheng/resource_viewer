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
    required this.currentPosition,
    this.onTap,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressEnd,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onScrubStart;
  final ValueChanged<Duration> onScrubUpdate;
  final ValueChanged<Duration> onScrubEnd;
  final Duration Function() currentPosition;
  final VoidCallback? onTap;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate;
  final GestureLongPressEndCallback? onLongPressEnd;

  @override
  State<VideoSeekGestureArea> createState() => _VideoSeekGestureAreaState();
}

class _VideoSeekGestureAreaState extends State<VideoSeekGestureArea> {
  Duration _dragStartPosition = Duration.zero;
  Duration _latestPosition = Duration.zero;
  Offset _dragDistance = Offset.zero;
  bool _scrubbing = false;
  bool _longPressing = false;

  static const double _scrubStartThreshold = 18;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        key: const ValueKey('video-seek-zone'),
        behavior: HitTestBehavior.translucent,
        excludeFromSemantics: true,
        onTap: widget.onTap,
        onLongPressStart: (details) {
          _longPressing = true;
          widget.onLongPressStart?.call(details);
        },
        onLongPressMoveUpdate: widget.onLongPressMoveUpdate,
        onLongPressEnd: (details) {
          _longPressing = false;
          widget.onLongPressEnd?.call(details);
        },
        onLongPressCancel: () => _longPressing = false,
        onPanStart: widget.duration == Duration.zero
            ? null
            : (_) {
                _dragStartPosition = widget.currentPosition();
                _latestPosition = _dragStartPosition;
                _dragDistance = Offset.zero;
                _scrubbing = false;
              },
        onPanUpdate: widget.duration == Duration.zero
            ? null
            : (details) {
                if (_longPressing) return;
                _dragDistance += details.delta;
                if (!_scrubbing) {
                  final horizontal = _dragDistance.dx.abs();
                  final vertical = _dragDistance.dy.abs();
                  if (horizontal < _scrubStartThreshold ||
                      horizontal <= vertical * 1.4) {
                    return;
                  }
                  _scrubbing = true;
                  widget.onScrubStart(_dragStartPosition);
                }
                final width = constraints.maxWidth;
                if (width <= 0) return;
                final delta =
                    widget.duration.inMilliseconds *
                    (_dragDistance.dx / width);
                final targetMs = (_dragStartPosition.inMilliseconds + delta)
                    .round()
                    .clamp(0, widget.duration.inMilliseconds);
                _latestPosition = Duration(milliseconds: targetMs);
                widget.onScrubUpdate(_latestPosition);
              },
        onPanEnd: widget.duration == Duration.zero
            ? null
            : (_) {
                if (_scrubbing) widget.onScrubEnd(_latestPosition);
                _scrubbing = false;
              },
        onPanCancel: widget.duration == Duration.zero
            ? null
            : () {
                if (_scrubbing) widget.onScrubEnd(_latestPosition);
                _scrubbing = false;
              },
      ),
    );
  }
}
