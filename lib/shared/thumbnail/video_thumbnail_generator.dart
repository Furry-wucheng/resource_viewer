import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../file_source/file_source.dart';
import 'thumbnail_generator.dart';

class VideoThumbnailGenerator implements ThumbnailGenerator {
  static const thumbWidth = 180;
  static const thumbHeight = 270;

  VideoThumbnailGenerator({this.outputDirectory});

  final String? outputDirectory;

  /// 截取并缩放视频首帧，供文件浏览器直接显示。
  Future<Uint8List?> generatePreview(
    FileSource source,
    String relativePath,
  ) async {
    Player? player;
    try {
      final absolutePath = _resolveAbsolutePath(source, relativePath);
      if (absolutePath == null || !await File(absolutePath).exists()) {
        return null;
      }
      player = Player();
      // 先短暂播放以确保 Windows/Linux/macOS 后端已解码出视频帧，
      // 再回到起点截图；仅 open(play: false) 在部分后端会一直返回空帧。
      await player.open(Media(absolutePath), play: true);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await player.pause();
      await player.seek(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final screenshot = await player.screenshot();
      if (screenshot == null || screenshot.isEmpty) return null;
      final decoded = img.decodeImage(screenshot);
      if (decoded == null) return null;
      final thumbnail = _resizeAndCrop(decoded, thumbWidth, thumbHeight);
      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 82));
    } catch (_) {
      return null;
    } finally {
      await player?.dispose();
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
    try {
      final rootPath = (source as dynamic).rootPath as String?;
      return rootPath == null ? null : p.join(rootPath, relativePath);
    } catch (_) {
      return null;
    }
  }

  img.Image _resizeAndCrop(img.Image source, int width, int height) {
    final scale = max(width / source.width, height / source.height);
    final scaledWidth = (source.width * scale).round();
    final scaledHeight = (source.height * scale).round();
    final scaled = img.copyResize(
      source,
      width: scaledWidth,
      height: scaledHeight,
      interpolation: img.Interpolation.linear,
    );
    return img.copyCrop(
      scaled,
      x: (scaledWidth - width) ~/ 2,
      y: (scaledHeight - height) ~/ 2,
      width: width,
      height: height,
    );
  }
}
