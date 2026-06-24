import 'package:flutter/material.dart';

/// 视频底部的大范围进度拖动热区。
///
/// 使用 [HorizontalDragGestureRecognizer] 直接与 PageView 的横向滚动竞争
/// Gesture Arena（同类型 recognizer，内层优先），确保拖动只触发 seek 不翻页。
///
/// 轻点不由本组件处理；外层 [GestureDetector] 负责 tap / double-tap / long-press。
class VideoSeekGestureArea extends StatefulWidget {
  const VideoSeekGestureArea({
    super.key,
    required this.position,
    required this.duration,
    required this.onScrubStart,
    required this.onScrubUpdate,
    required this.onScrubEnd,
    required this.currentPosition,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onScrubStart;
  final ValueChanged<Duration> onScrubUpdate;
  final ValueChanged<Duration> onScrubEnd;
  final Duration Function() currentPosition;

  @override
  State<VideoSeekGestureArea> createState() => _VideoSeekGestureAreaState();
}

class _VideoSeekGestureAreaState extends State<VideoSeekGestureArea> {
  Duration _dragStartPosition = Duration.zero;
  Duration _latestPosition = Duration.zero;
  double _dragDeltaX = 0;
  bool _scrubbing = false;

  /// 水平拖动起步门槛（px）：累计水平位移需超过此值才进入 scrubbing，
  /// 避免轻触/微动误触发 seek（旧代码回归）。
  static const double _scrubStartThreshold = 18;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final enabled = widget.duration > Duration.zero;
        return GestureDetector(
          key: const ValueKey('video-seek-zone'),
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          // 横向拖动 → 进度 scrubbing（与 PageView 横向滚动同类型竞争，内层胜出）
          onHorizontalDragStart:
              enabled
                  ? (_) {
                      // 仅记录起点，不触发 onScrubStart；需累计超过门槛才算 scrubbing。
                      _dragStartPosition = widget.currentPosition();
                      _latestPosition = _dragStartPosition;
                      _dragDeltaX = 0;
                      _scrubbing = false;
                    }
                  : null,
          onHorizontalDragUpdate:
              enabled
                  ? (details) {
                      final width = constraints.maxWidth;
                      if (width <= 0) return;
                      _dragDeltaX += details.delta.dx;
                      if (!_scrubbing) {
                        if (_dragDeltaX.abs() < _scrubStartThreshold) return;
                        _scrubbing = true;
                        widget.onScrubStart(_dragStartPosition);
                      }
                      final deltaMs = widget.duration.inMilliseconds *
                          (_dragDeltaX / width);
                      final targetMs = (_dragStartPosition.inMilliseconds +
                              deltaMs.round())
                          .clamp(0, widget.duration.inMilliseconds);
                      _latestPosition = Duration(milliseconds: targetMs);
                      widget.onScrubUpdate(_latestPosition);
                    }
                  : null,
          onHorizontalDragEnd:
              enabled
                  ? (_) {
                      if (_scrubbing) widget.onScrubEnd(_latestPosition);
                      _scrubbing = false;
                    }
                  : null,
          onHorizontalDragCancel:
              enabled
                  ? () {
                      if (_scrubbing) widget.onScrubEnd(_latestPosition);
                      _scrubbing = false;
                    }
                  : null,
        );
      },
    );
  }
}
