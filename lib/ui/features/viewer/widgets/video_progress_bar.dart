import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

/// 视频进度条组件
///
/// 显示播放进度、缓冲进度，支持拖动跳转。
class VideoProgressBar extends StatelessWidget {
  const VideoProgressBar({
    super.key,
    required this.player,
    this.positionOverride,
    this.durationOverride,
    this.onScrubStart,
    this.onScrubUpdate,
    this.onScrubEnd,
  });

  final Player player;
  final Duration? positionOverride;
  final Duration? durationOverride;
  final ValueChanged<Duration>? onScrubStart;
  final ValueChanged<Duration>? onScrubUpdate;
  final ValueChanged<Duration>? onScrubEnd;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.stream.position,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration?>(
          stream: player.stream.duration,
          builder: (context, durationSnapshot) {
            final position =
                positionOverride ??
                positionSnapshot.data ??
                player.state.position;
            final snapshotDuration = durationSnapshot.data;
            final stateDuration = player.state.duration;
            final duration =
                snapshotDuration != null && snapshotDuration > Duration.zero
                ? snapshotDuration
                : durationOverride != null && durationOverride! > Duration.zero
                ? durationOverride!
                : stateDuration;

            return Container(
              key: const ValueKey('video-progress-controls'),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 8,
                top: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  StreamBuilder<bool>(
                    stream: player.stream.playing,
                    builder: (context, snapshot) {
                      final playing = snapshot.data ?? false;
                      return IconButton(
                        tooltip: playing ? '暂停' : '播放',
                        onPressed: player.playOrPause,
                        icon: Icon(
                          playing ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  // 当前时间
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  // 进度条
                  Expanded(
                    child: Slider(
                      value: duration.inMilliseconds > 0
                          ? position.inMilliseconds / duration.inMilliseconds
                          : 0.0,
                      onChangeStart: duration == Duration.zero
                          ? null
                          : (_) => onScrubStart?.call(position),
                      onChanged: duration == Duration.zero
                          ? null
                          : (value) {
                              final target = _positionFor(value, duration);
                              if (onScrubUpdate != null) {
                                onScrubUpdate!(target);
                              } else {
                                player.seek(target);
                              }
                            },
                      onChangeEnd: duration == Duration.zero
                          ? null
                          : (value) =>
                                onScrubEnd?.call(_positionFor(value, duration)),
                      activeColor: Colors.white,
                      inactiveColor: Colors.white30,
                    ),
                  ),
                  // 总时长
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Duration _positionFor(double fraction, Duration duration) =>
      Duration(milliseconds: (fraction * duration.inMilliseconds).round());

  /// 格式化时长
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
