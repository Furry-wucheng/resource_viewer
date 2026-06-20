import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'video_progress_bar.dart';
import 'video_seek_gesture_area.dart';

/// 让查看器页面可以通过键盘控制当前视频，而无需暴露 Player。
class VideoPlaybackController {
  Player? _player;

  Future<void> playOrPause() async {
    await _player?.playOrPause();
  }

  void _attach(Player player) => _player = player;

  void _detach(Player player) {
    if (identical(_player, player)) _player = null;
  }
}

/// 视频播放器组件
///
/// 使用 media_kit 渲染视频，支持播放/暂停、进度拖动、倍速控制。
class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({
    super.key,
    required this.filePath,
    this.onToggleToolbar,
    this.controlsVisible = true,
    this.active = true,
    this.playbackController,
  });

  final String filePath;
  final VoidCallback? onToggleToolbar;
  final bool controlsVisible;
  final bool active;
  final VideoPlaybackController? playbackController;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final Player _player;
  late final VideoController _controller;
  bool _speedMode = false;
  double _speed = 1;
  double _dragOriginY = 0;
  Timer? _scrubTimer;
  Duration? _scrubPosition;
  Duration? _pendingSeek;
  bool _seekInProgress = false;
  bool _scrubEnding = false;
  bool _resumeAfterScrub = false;

  static const _speedSteps = <double>[1, 1.25, 1.5, 1.75, 2, 2.5, 3];

  @override
  void initState() {
    super.initState();
    _player = Player();
    widget.playbackController?._attach(_player);
    _controller = VideoController(_player);
    _player.open(Media(widget.filePath), play: widget.active);
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.playbackController, widget.playbackController)) {
      oldWidget.playbackController?._detach(_player);
      widget.playbackController?._attach(_player);
    }
    if (oldWidget.active && !widget.active) _player.pause();
  }

  @override
  void dispose() {
    _scrubTimer?.cancel();
    widget.playbackController?._detach(_player);
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: widget.onToggleToolbar,
      onDoubleTap: () {
        // 双击播放/暂停
        _player.playOrPause();
      },
      onLongPressStart: _startSpeedMode,
      onLongPressMoveUpdate: _updateSpeedMode,
      onLongPressEnd: (_) => _endSpeedMode(),
      onSecondaryLongPressStart: _startSpeedMode,
      onSecondaryLongPressMoveUpdate: _updateSpeedMode,
      onSecondaryLongPressEnd: (_) => _endSpeedMode(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 视频渲染
          ExcludeSemantics(
            child: Video(controller: _controller, controls: NoVideoControls),
          ),
          // 播放/暂停按钮（加载时显示）
          StreamBuilder<bool>(
            stream: _player.stream.playing,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data ?? false;
              if (isPlaying) return const SizedBox.shrink();
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.sizeOf(context).height * 0.3,
            child: StreamBuilder<Duration>(
              stream: _player.stream.position,
              builder: (context, positionSnapshot) => StreamBuilder<Duration?>(
                stream: _player.stream.duration,
                builder: (context, durationSnapshot) => VideoSeekGestureArea(
                  position:
                      _scrubPosition ??
                      positionSnapshot.data ??
                      _player.state.position,
                  duration: durationSnapshot.data ?? _player.state.duration,
                  onScrubStart: _startScrub,
                  onScrubUpdate: _updateScrub,
                  onScrubEnd: _endScrub,
                  onTap: widget.onToggleToolbar,
                ),
              ),
            ),
          ),
          if (widget.controlsVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressBar(
                player: _player,
                positionOverride: _scrubPosition,
                onScrubStart: _startScrub,
                onScrubUpdate: _updateScrub,
                onScrubEnd: _endScrub,
              ),
            ),
          if (_scrubPosition case final position?)
            Positioned(
              bottom: widget.controlsVisible ? 72 : 24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    _formatDuration(position),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          if (_speedMode)
            Positioned(
              bottom: MediaQuery.sizeOf(context).height * 0.22,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  child: Text(
                    '${_speed.toStringAsFixed(_speed % 1 == 0 ? 1 : 2)}x',
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _startSpeedMode(LongPressStartDetails details) {
    _dragOriginY = details.globalPosition.dy;
    _setSpeed(2);
    setState(() => _speedMode = true);
  }

  void _updateSpeedMode(LongPressMoveUpdateDetails details) {
    final offset = ((_dragOriginY - details.globalPosition.dy) / 48).round();
    final index = (4 + offset).clamp(0, _speedSteps.length - 1);
    _setSpeed(_speedSteps[index]);
  }

  void _endSpeedMode() {
    _setSpeed(1);
    if (mounted) setState(() => _speedMode = false);
  }

  void _setSpeed(double speed) {
    if (_speed == speed) return;
    _speed = speed;
    _player.setRate(speed);
    if (mounted) setState(() {});
  }

  void _startScrub(Duration position) {
    _scrubTimer?.cancel();
    _pendingSeek = null;
    _scrubEnding = false;
    _resumeAfterScrub = _player.state.playing;
    if (_resumeAfterScrub) unawaited(_player.pause());
    setState(() => _scrubPosition = position);
  }

  void _updateScrub(Duration position) {
    if (!mounted) return;
    setState(() => _scrubPosition = position);
    _pendingSeek = position;
    _scrubTimer ??= Timer(const Duration(milliseconds: 50), () {
      _scrubTimer = null;
      unawaited(_flushSeek());
    });
  }

  void _endScrub(Duration position) {
    _scrubTimer?.cancel();
    _scrubTimer = null;
    _pendingSeek = position;
    _scrubEnding = true;
    unawaited(_flushSeek());
  }

  Future<void> _flushSeek() async {
    if (_seekInProgress) return;
    final target = _pendingSeek;
    if (target == null) return;
    _pendingSeek = null;
    _seekInProgress = true;
    await _player.seek(target);
    _seekInProgress = false;

    if (_pendingSeek != null) {
      await _flushSeek();
      return;
    }
    if (!_scrubEnding) return;

    _scrubEnding = false;
    if (mounted) setState(() => _scrubPosition = null);
    if (_resumeAfterScrub) await _player.play();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
