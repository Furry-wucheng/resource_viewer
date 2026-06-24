import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

import '../../../../data/services/video_stream_service.dart';
import '../../../../shared/content_provider/video_media_source.dart';
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
    required this.source,
    this.onToggleToolbar,
    this.controlsVisible = true,
    this.active = true,
    this.playbackController,
  });

  final VideoMediaSource source;
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
  late final VideoStreamService _streamService;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration?> _durationSubscription;
  bool _speedMode = false;
  double _speed = 1;
  double _dragOriginY = 0;
  Duration? _scrubPosition;
  Duration? _pendingSeek;
  Duration? _displayPositionOverride;
  Duration _lastVisiblePosition = Duration.zero;
  Duration _lastKnownDuration = Duration.zero;
  bool _seekInProgress = false;
  bool _scrubEnding = false;
  bool _resumeAfterScrub = false;
  bool _wasPlayingBeforeSpeedMode = false;
  int _seekGeneration = 0;
  Timer? _seekSettleTimer;
  VideoStreamHandle? _streamHandle;

  static const _speedSteps = <double>[1, 1.25, 1.5, 1.75, 2, 2.5, 3];

  @override
  void initState() {
    super.initState();
    _streamService = context.read<VideoStreamService>();
    _player = Player();
    _positionSubscription = _player.stream.position.listen((position) {
      _lastVisiblePosition = position;
      final override = _displayPositionOverride;
      if (override == null || _isScrubbing) return;
      if ((position - override).abs() < const Duration(milliseconds: 500)) {
        _clearDisplayPositionOverride();
      }
    });
    _durationSubscription = _player.stream.duration.listen((duration) {
      if (duration == Duration.zero) return;
      _lastKnownDuration = duration;
      if (mounted) setState(() {});
    });
    widget.playbackController?._attach(_player);
    _controller = VideoController(_player);
    unawaited(_open(widget.source));
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.playbackController, widget.playbackController)) {
      oldWidget.playbackController?._detach(_player);
      widget.playbackController?._attach(_player);
    }
    if (!_sameSource(oldWidget.source, widget.source)) {
      unawaited(_open(widget.source));
    }
    if (oldWidget.active && !widget.active) _player.pause();
  }

  @override
  void dispose() {
    _seekSettleTimer?.cancel();
    unawaited(_positionSubscription.cancel());
    unawaited(_durationSubscription.cancel());
    unawaited(_revokeStreamHandle());
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
                  position: _displayPosition(positionSnapshot.data),
                  duration: _displayDuration(durationSnapshot.data),
                  currentPosition: _currentPlaybackPosition,
                  onScrubStart: _startScrub,
                  onScrubUpdate: _updateScrub,
                  onScrubEnd: _endScrub,
                  onTap: widget.onToggleToolbar,
                  onLongPressStart: _startSpeedMode,
                  onLongPressMoveUpdate: _updateSpeedMode,
                  onLongPressEnd: (_) => _endSpeedMode(),
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
                positionOverride: _displayPositionOverride ?? _scrubPosition,
                durationOverride: _lastKnownDuration,
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
    if (_speedMode) return;
    _dragOriginY = details.globalPosition.dy;
    _seekGeneration++;
    _pendingSeek = null;
    _scrubEnding = false;
    _scrubPosition = null;
    _displayPositionOverride = null;
    _wasPlayingBeforeSpeedMode = _player.state.playing;
    _setSpeed(2);
    unawaited(_player.play());
    setState(() => _speedMode = true);
  }

  Future<void> _open(VideoMediaSource source) async {
    await _revokeStreamHandle();
    if (!mounted) return;
    if (source.kind == VideoMediaSourceKind.localFile) {
      await _player.open(Media(source.path!), play: widget.active);
      _syncCachedPlaybackState();
      return;
    }

    final handle = await _streamService.register(
      fileSource: source.fileSource!,
      relativePath: source.relativePath!,
      fileSize: source.fileSize!,
    );
    if (!mounted) {
      await _streamService.revoke(handle);
      return;
    }
    _streamHandle = handle;
    await _player.open(Media(handle.uri.toString()), play: widget.active);
    _syncCachedPlaybackState();
  }

  Future<void> _revokeStreamHandle() async {
    final handle = _streamHandle;
    if (handle == null) return;
    _streamHandle = null;
    await _streamService.revoke(handle);
  }

  bool _sameSource(VideoMediaSource a, VideoMediaSource b) {
    if (a.kind != b.kind) return false;
    return switch (a.kind) {
      VideoMediaSourceKind.localFile => a.path == b.path,
      VideoMediaSourceKind.proxiedFile =>
        identical(a.fileSource, b.fileSource) &&
            a.relativePath == b.relativePath &&
            a.fileSize == b.fileSize,
    };
  }

  void _updateSpeedMode(LongPressMoveUpdateDetails details) {
    final offset = ((_dragOriginY - details.globalPosition.dy) / 48).round();
    final index = (4 + offset).clamp(0, _speedSteps.length - 1);
    _setSpeed(_speedSteps[index]);
  }

  void _endSpeedMode() {
    _setSpeed(1);
    if (!_wasPlayingBeforeSpeedMode) {
      unawaited(_player.pause());
    }
    if (mounted) setState(() => _speedMode = false);
  }

  void _setSpeed(double speed) {
    if (_speed == speed) return;
    _speed = speed;
    _player.setRate(speed);
    if (mounted) setState(() {});
  }

  void _startScrub(Duration position) {
    if (_speedMode) _endSpeedMode();
    _seekGeneration++;
    _seekSettleTimer?.cancel();
    _pendingSeek = null;
    _scrubEnding = false;
    _resumeAfterScrub = _player.state.playing;
    if (_resumeAfterScrub) unawaited(_player.pause());
    setState(() {
      _scrubPosition = position;
      _displayPositionOverride = position;
    });
  }

  void _updateScrub(Duration position) {
    if (!mounted) return;
    _pendingSeek = position;
    setState(() {
      _scrubPosition = position;
      _displayPositionOverride = position;
    });
  }

  void _endScrub(Duration position) {
    _pendingSeek = position;
    _scrubEnding = true;
    if (mounted) {
      setState(() {
        _scrubPosition = position;
        _displayPositionOverride = position;
      });
    }
    unawaited(_flushSeek());
  }

  Future<void> _flushSeek() async {
    if (_seekInProgress) return;
    final target = _pendingSeek;
    if (target == null) return;
    final generation = _seekGeneration;
    _pendingSeek = null;
    _seekInProgress = true;
    await _player.seek(target);
    _seekInProgress = false;
    if (generation != _seekGeneration) return;
    _lastVisiblePosition = target;

    if (_pendingSeek != null) {
      await _flushSeek();
      return;
    }
    if (!_scrubEnding) return;

    _scrubEnding = false;
    if (mounted) {
      setState(() {
        _scrubPosition = null;
        _displayPositionOverride = target;
      });
    }
    _scheduleDisplayOverrideClear();
    if (_resumeAfterScrub) await _player.play();
  }

  bool get _isScrubbing =>
      _scrubPosition != null ||
      _pendingSeek != null ||
      _seekInProgress ||
      _scrubEnding;

  Duration _displayPosition(Duration? streamPosition) =>
      _displayPositionOverride ??
      _scrubPosition ??
      streamPosition ??
      _lastVisiblePosition;

  Duration _currentPlaybackPosition() {
    final position = _player.state.position;
    if (position > Duration.zero) return position;
    return _lastVisiblePosition;
  }

  Duration _displayDuration(Duration? streamDuration) {
    final candidates = [
      streamDuration,
      _player.state.duration,
      _lastKnownDuration,
    ];
    for (final duration in candidates) {
      if (duration != null && duration > Duration.zero) return duration;
    }
    return Duration.zero;
  }

  void _syncCachedPlaybackState() {
    final position = _player.state.position;
    final duration = _player.state.duration;
    if (position > Duration.zero) _lastVisiblePosition = position;
    if (duration > Duration.zero) _lastKnownDuration = duration;
    if (mounted) setState(() {});
  }

  void _scheduleDisplayOverrideClear() {
    _seekSettleTimer?.cancel();
    _seekSettleTimer = Timer(const Duration(milliseconds: 900), () {
      _clearDisplayPositionOverride();
    });
  }

  void _clearDisplayPositionOverride() {
    if (!mounted || _displayPositionOverride == null || _isScrubbing) return;
    setState(() => _displayPositionOverride = null);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
