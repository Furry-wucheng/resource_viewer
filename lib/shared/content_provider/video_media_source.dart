import '../file_source/file_source.dart';

enum VideoMediaSourceKind { localFile, proxiedFile }

/// 视频播放来源。
///
/// 本地文件可直接交给 media_kit；SMB 等非本地源通过本地 HTTP Range
/// 代理桥接到 [FileSource.readRange]。
class VideoMediaSource {
  const VideoMediaSource.localFile(this.path)
    : kind = VideoMediaSourceKind.localFile,
      fileSource = null,
      relativePath = null,
      fileSize = null;

  const VideoMediaSource.proxiedFile({
    required this.fileSource,
    required this.relativePath,
    required this.fileSize,
  }) : kind = VideoMediaSourceKind.proxiedFile,
       path = null;

  final VideoMediaSourceKind kind;
  final String? path;
  final FileSource? fileSource;
  final String? relativePath;
  final int? fileSize;
}
