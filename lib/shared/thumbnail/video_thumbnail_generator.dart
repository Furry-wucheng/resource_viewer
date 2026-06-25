import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../file_source/file_source.dart';
import '../file_source/local_file_source.dart';
import 'thumbnail_generator.dart';

class VideoThumbnailGenerator implements ThumbnailGenerator {
  VideoThumbnailGenerator({
    this.outputDirectory,
    FcNativeVideoThumbnail? thumbnailer,
  }) : _thumbnailer = thumbnailer ?? FcNativeVideoThumbnail();

  final String? outputDirectory;
  final FcNativeVideoThumbnail _thumbnailer;

  /// 原生视频解码串行执行，避免文件网格同时创建过多解码任务。
  static Future<void> _captureQueue = Future.value();

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _captureQueue = _captureQueue.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  /// 截取并缩放视频首帧，供文件浏览器直接显示。
  Future<Uint8List?> generatePreview(FileSource source, String relativePath) =>
      _serialize(() => _generatePreview(source, relativePath));

  Future<Uint8List?> _generatePreview(
    FileSource source,
    String relativePath,
  ) async {
    try {
      final absolutePath = _resolveAbsolutePath(source, relativePath);
      if (absolutePath == null || !await File(absolutePath).exists()) {
        return null;
      }
      // 原生 API 已完成缩放，无需纯 Dart 二次解码+裁剪。
      // 传入 thumbWidth/thumbHeight 让原生直接输出目标尺寸。
      final bytes = await _thumbnailer.saveThumbnailToBytes(
        srcFile: absolutePath,
        width: ThumbnailGenerator.thumbWidth,
        height: ThumbnailGenerator.thumbHeight,
        quality: ThumbnailGenerator.jpegQuality,
      );
      if (bytes == null || bytes.isEmpty) return null;
      // 验证输出有效性（仅读 header，不全量解码）
      final decoded = img.decodeImage(bytes);
      if (decoded == null || decoded.width <= 1 || decoded.height <= 1) {
        return null;
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> generate(
    FileSource source,
    String relativePath,
    String resourceId,
  ) async {
    try {
      final bytes = await generatePreview(source, relativePath);
      if (bytes == null) return null;
      final root =
          outputDirectory ?? (await getApplicationCacheDirectory()).path;
      final directory = Directory(p.join(root, 'thumbs'));
      await directory.create(recursive: true);
      final file = File(p.join(directory.path, 'thumb_$resourceId.jpg'));
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  String? _resolveAbsolutePath(FileSource source, String relativePath) {
    if (source is! LocalFileSource || relativePath.isEmpty) return null;
    return p.normalize(p.join(source.rootPath, relativePath));
  }
}
